select * from xsd.transport_files;
select * from xsd.transport_attributes;

-- Генерация выражений ЯОД/DDL
select 'CREATE SCHEMA IF NOT EXIST "' || set_config('ГАР.схема', 'data', false) ||'";';
select * from xsd.table_ddl;
select ddl from xsd.table_ddl;

select * from xsd.row_ddl;

-- Сравнение таблиц в выбранной схеме с эталонной структурой ГАР
-- Создание таблицы переноса данных в таблицы
create table xsd.pg_tables as
with t as (
select *
  from information_schema."tables" t
 where t.table_catalog = 'Государственный адресный реестр'
   and t.table_schema = current_setting('ГАР.схема', false)
)   
select table_catalog,
       table_schema,
       table_name,
       tf.xml_file_prefix,
       tf.xsd_filename,
       tf.root_node,
       tf.singular_transport_node,
       tf.xsd_descr_singular
  from t
  full join xsd.transport_files tf
 using (table_name);

ALTER TABLE xsd.pg_tables ADD CONSTRAINT pg_tables_xml_pk PRIMARY KEY (xml_file_prefix);
ALTER TABLE xsd.pg_tables ADD CONSTRAINT pg_tables_db_un UNIQUE (table_catalog,table_schema,table_name);

-- Сравнение колонок таблиц в выбранной схеме с эталонной структурой ГАР
-- Создание таблицы переноса данных в колонки
create table xsd.pg_columns as
with c as (
select *
  from information_schema."columns" c
 where c.table_catalog = 'Государственный адресный реестр'
   and c.table_schema = current_setting('ГАР.схема', false)
   )
select table_catalog,
       table_schema,
       table_name,
       column_name,
       ordinal_position,
       transport_attribute,
       xml_file_prefix,
       xsd_filename
  from c
  full join xsd.transport_attributes ta
 using (table_name, column_name);

-- XML атрибуты уникальны, хотя могут быть недозаполнены
ALTER TABLE xsd.pg_columns ADD CONSTRAINT pg_columns_xml_un UNIQUE (transport_attribute,xml_file_prefix);
-- Объект БД уникален
ALTER TABLE xsd.pg_columns ADD CONSTRAINT pg_columns_db_un UNIQUE (table_catalog,table_schema,table_name,column_name);
-- Колонки относятся к уже занесённым таблицам
ALTER TABLE xsd.pg_columns ADD CONSTRAINT pg_columns_fk FOREIGN KEY (table_catalog,table_schema,table_name) REFERENCES xsd.pg_tables(table_catalog,table_schema,table_name) ON DELETE CASCADE ON UPDATE CASCADE;

-- Выборка параметров вызова программы
with col_ord as (
select *
  from xsd.pg_columns pc
 inner join xsd.pg_tables pt
 using (table_catalog, table_schema, table_name)  
  where pc.xml_file_prefix ~ '^PARAM.*'
order by table_catalog, table_schema, table_name, ordinal_position asc)
select ' -a ''' || string_agg(transport_attribute, ',') || '''' ||
       ' -t ''"' || table_schema || '"."' || table_name || '"''' ||
       ' -p ''' || root_node || '/' || singular_transport_node || ''' ' "bash"
from col_ord
group by table_catalog, table_schema, table_name, root_node, singular_transport_node;


create view xsd.data_files_prefix as
select *,
       ((regexp_match(fileaddress, '^\d+(?=/)'))[1])::varchar "Регион",
       ((regexp_match(fileaddress, '(?<=(^|/))\D+(?=_\d)'))[1])::varchar "Префикс",
       ((regexp_match(fileaddress, '(?<=(^|/)\D+_)\d+'))[1])::date "Префикс даты",
       ((regexp_match(fileaddress, '(?<=(^|/)\D+_\d+_)[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}'))[1])::uuid "uuid"
from xsd.ziped_xml_files zf;

with p AS (
select distinct replace("Префикс", 'AS_', '') pref from xsd.data_files_prefix
)
select * from p where pref not in (select pt.xml_file_prefix  from xsd.pg_tables pt)


