-- СЛОВАРИ ПЕРЕНОСА ДАННЫХ ИЗ XML В ОБЪЕКТЫ POSTGRESQL
-- По желанию не все атрибуты XML могут быть задействованы, но
-- в перегрузке всегда принимают столько полей, сколько их есть в принимающей таблице.
-- Если данных в XML для нет для некоторых полей целевой таблицы, то
-- в цепочке используемых атрибутов можно писать пропуск - две запятых сразу. 


select '-- Схема целевых таблиц называется "' || set_config('ГАР.схема', 'data', false) ||'";';

-- Сотнесение таблиц в выбранной схеме с эталонной структурой ГАР
-- Создание таблицы переноса данных XML в таблицы
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

-- Сотнесение колонок таблиц в выбранной схеме с эталонной структурой ГАР
-- Создание таблицы переноса значений XML атрибутов в колонки
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
-- При редактировании соответствия таблиц, колонки переносятся вслед за своей таблицей
ALTER TABLE xsd.pg_columns ADD CONSTRAINT pg_columns_fk FOREIGN KEY (table_catalog,table_schema,table_name)
REFERENCES xsd.pg_tables(table_catalog,table_schema,table_name) ON DELETE CASCADE ON UPDATE CASCADE;

-- Параметры вызова программы
-- формируются динамически из действующих словарей соответствия
-- здесь приводится версия по умолчанию без исправлений
create view xsd.program_call_parameters as
with col_ord as (
select table_catalog, table_schema, table_name,
       transport_attribute, root_node, singular_transport_node, pt.xml_file_prefix
  from xsd.pg_columns pc
 inner join xsd.pg_tables pt
 using (table_catalog, table_schema, table_name)  
  --where pc.xml_file_prefix ~ '^PARAM.*'
order by table_catalog, table_schema, table_name, ordinal_position asc)
select table_name,
       xml_file_prefix, 
       ' -t ''"' || table_schema || '"."' || table_name || '"''' ||
       ' -a ''' || string_agg(transport_attribute, ',') || '''' ||       
       ' -p ''' || root_node || '/' || singular_transport_node || ''' ' "bash"       
from col_ord
group by table_catalog, table_schema, table_name, root_node, singular_transport_node, xml_file_prefix;

-- Тестовый вывод получившихся словарей и параметров
select * from xsd.pg_tables;
select * from xsd.pg_columns;
select * from xsd.program_call_parameters;
