-- create user "Государственный адресный реестр" password 'qwertyuiop';
-- create database "Государственный адресный реестр" owner "Государственный адресный реестр";

-- drop schema xsd cascade;
create schema xsd;
create table xsd.official_data (
	xsd_id serial,
	loading_session_id int not null,
	tstamp timestamp not null default now(),
	xsd_filename varchar(256) not null,
	xsd xml not NULL
);

create table xsd.ziped_xml_files (id serial, fileaddress varchar(512));

-----------------------------------------------------------------------------------------------------------------------
-- Таблицы
create table xsd.table_names as
with base as (select
xml $$
<table_names xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
<row>
  <xml_file_prefix>ADDR_OBJ</xml_file_prefix>
  <table_name>Адресообразующие элементы</table_name>
</row>
<row>
  <xml_file_prefix>ADDR_OBJ_DIVISION</xml_file_prefix>
  <table_name>Операции переподчинения</table_name>
</row>
<row>
  <xml_file_prefix>ADDR_OBJ_TYPES</xml_file_prefix>
  <table_name>Типы адресных объектов</table_name>
</row>
<row>
  <xml_file_prefix>ADM_HIERARCHY</xml_file_prefix>
  <table_name>Иерархия административная</table_name>
</row>
<row>
  <xml_file_prefix>APARTMENTS</xml_file_prefix>
  <table_name>Помещения</table_name>
</row>
<row>
  <xml_file_prefix>APARTMENT_TYPES</xml_file_prefix>
  <table_name>Типы помещений</table_name>
</row>
<row>
  <xml_file_prefix>CARPLACES</xml_file_prefix>
  <table_name>Машино-места</table_name>
</row>
<row>
  <xml_file_prefix>CHANGE_HISTORY</xml_file_prefix>
  <table_name>История изменений</table_name>
</row>
<row>
  <xml_file_prefix>HOUSES</xml_file_prefix>
  <table_name>№ домов улиц населённых пунктов</table_name>
</row>
<row>
  <xml_file_prefix>HOUSE_TYPES</xml_file_prefix>
  <table_name>Типы домов</table_name>
</row>
<row>
  <xml_file_prefix>MUN_HIERARCHY</xml_file_prefix>
  <table_name>Иерархия муниципальная</table_name>
</row>
<row>
  <xml_file_prefix>NORMATIVE_DOCS</xml_file_prefix>
  <table_name>Документы обоснования адресации</table_name>
</row>
<row>
  <xml_file_prefix>NORMATIVE_DOCS_KINDS</xml_file_prefix>
  <table_name>Виды нормативных документов</table_name>
</row>
<row>
  <xml_file_prefix>NORMATIVE_DOCS_TYPES</xml_file_prefix>
  <table_name>Типы нормативных документов</table_name>
</row>
<row>
  <xml_file_prefix>OBJECT_LEVELS</xml_file_prefix>
  <table_name>Уровни адресных объектов</table_name>
</row>
<row>
  <xml_file_prefix>OPERATION_TYPES</xml_file_prefix>
  <table_name>Статусы действия</table_name>
</row>
<row>
  <xml_file_prefix>PARAM</xml_file_prefix>
  <table_name>Параметры адр. эл. и недвижимости</table_name>
</row>
<row>
  <xml_file_prefix>PARAM_TYPES</xml_file_prefix>
  <table_name>Типы параметров</table_name>
</row>
<row>
  <xml_file_prefix>REESTR_OBJECTS</xml_file_prefix>
  <table_name>Коды адресных элементов</table_name>
</row>
<row>
  <xml_file_prefix>ROOMS</xml_file_prefix>
  <table_name>Комнаты</table_name>
</row>
<row>
  <xml_file_prefix>ROOM_TYPES</xml_file_prefix>
  <table_name>Типы комнат</table_name>
</row>
<row>
  <xml_file_prefix>STEADS</xml_file_prefix>
  <table_name>Земельные участки</table_name>
</row>
<row>
  <xml_file_prefix>STEADS_PARAMS</xml_file_prefix>
  <table_name>Параметры земельных участков</table_name>
  <xsd_file_pefix>PARAM</xsd_file_pefix>
</row>
<row>
  <xml_file_prefix>HOUSES_PARAMS</xml_file_prefix>
  <table_name>Параметры домов</table_name>
  <xsd_file_pefix>PARAM</xsd_file_pefix>  
</row>
<row>
  <xml_file_prefix>ROOMS_PARAMS</xml_file_prefix>
  <table_name>Параметры помещений</table_name>
  <xsd_file_pefix>PARAM</xsd_file_pefix>  
</row>
<row>
  <xml_file_prefix>CARPLACES_PARAMS</xml_file_prefix>
  <table_name>Параметры машиномест</table_name>
  <xsd_file_pefix>PARAM</xsd_file_pefix>  
</row>
<row>
  <xml_file_prefix>ADDR_OBJ_PARAMS</xml_file_prefix>
  <table_name>Параметры адресных объектов</table_name>
  <xsd_file_pefix>PARAM</xsd_file_pefix>
</row>
<row>
  <xml_file_prefix>ADDHOUSE_TYPES</xml_file_prefix>
  <table_name>Добавочные параметры домов</table_name>
  <xsd_file_pefix>PARAM</xsd_file_pefix>
</row>
<row>
  <xml_file_prefix>APARTMENTS_PARAMS</xml_file_prefix>
  <table_name>Параметры квартир</table_name>
  <xsd_file_pefix>PARAM</xsd_file_pefix>
</row>
</table_names>
$$ as data
),
base_table as (
select xmlt.* from base, xmltable ('table_names/row'
                PASSING data
                COLUMNS xml_file_prefix text PATH 'xml_file_prefix',
                        table_name text PATH 'table_name',
                        xsd_file_pefix text PATH 'xsd_file_pefix'
                        ) xmlt
)
select xml_file_prefix,
       table_name,
       coalesce (xsd_file_pefix, xml_file_prefix) xsd_file_pefix
  from base_table;

create view xsd.transport_xsd as
with ns as (
select ARRAY[ ARRAY['xs', 'http://www.w3.org/2001/XMLSchema'] ] as xsdns,
       '/xs:schema/xs:element/' as root
)
select xsd_id,       
       loading_session_id,
       tstamp,
       xsd_filename,
       (regexp_matches(xsd_filename,'(?<=AS_)\D+(?=_\d)'))[1] xml_file_prefix,
       ((xpath( root || '@name', xsd, ns.xsdns))[1])::text root_node,       
       ((xpath( root || 'xs:annotation/xs:documentation/text()', xsd, ns.xsdns))[1])::text xsd_descr_general,
       ((xpath( root || 'xs:complexType/xs:sequence/xs:element/xs:annotation/xs:documentation/text()', xsd, ns.xsdns))[1])::text xsd_descr_singular,       
       coalesce (((xpath( root || 'xs:complexType/xs:sequence/xs:element/@name', xsd, ns.xsdns))[1])::text,
       ((xpath( root || 'xs:complexType/xs:sequence/xs:element/@ref', xsd, ns.xsdns))[1])::text ) singular_transport_node,
	   xsd	   
  from xsd.official_data o 
  join ns
    on true;
 
create view xsd.transport_files as
select row_number() over () "№",
       xsd_id,
       loading_session_id,
       tstamp,
       xsd_filename,
       coalesce(t.xml_file_prefix, tx.xml_file_prefix) xml_file_prefix,
       table_name,
       root_node,
       singular_transport_node,
       xsd_descr_general, xsd_descr_singular, xsd
  from xsd.transport_xsd tx
  full join xsd.table_names t
    on tx.xml_file_prefix = t.xsd_file_pefix;

-----------------------------------------------------------------------------------------------------------------------
-- Отдельные атрибуты
-- Цитируются исходные данные
create or replace view xsd.xsd_attributes as
with ns as (
select ARRAY[ ARRAY['xs', 'http://www.w3.org/2001/XMLSchema'] ] as xsdns,
       '/xs:schema/xs:element/' as root
),
arr as (
select xsd_id,
       loading_session_id,
       tstamp,
       xsd_filename,
       ((xpath( root || '@name', xsd, ns.xsdns))[1])::text root_node,
       unnest(xpath(root || 'xs:complexType/xs:sequence/xs:element/xs:complexType/xs:attribute', xsd, ns.xsdns)) xsda,
       ns.*
  from xsd.official_data
  join ns
    on true
)
select xsd_id,
       loading_session_id,
       tstamp,
       xsd_filename,
       root_node,       
       ((xpath( '/xs:attribute/@name', xsda, xsdns))[1])::text transport_attribute,
       ((xpath( '/xs:attribute/xs:annotation/xs:documentation/text()', xsda, xsdns))[1])::text "name",
       ((xpath( '/xs:attribute/@use', xsda, xsdns))[1])::text "not null",
       ((xpath( '/xs:attribute/@type', xsda, xsdns))[1])::text type1,
       ((xpath( '/xs:attribute/xs:simpleType/xs:restriction/@base', xsda, xsdns))[1])::text type2,
       ((xpath( '/xs:attribute/xs:simpleType/xs:restriction/xs:totalDigits/@value', xsda, xsdns))[1])::text::int2 "cardinality",
       ((xpath( '/xs:attribute/xs:simpleType/xs:restriction/xs:length/@value', xsda, xsdns))[1])::text::int2 "length",
       array_to_string((xpath( '/xs:attribute/xs:simpleType/xs:restriction/xs:enumeration/@value', xsda, xsdns))::text[], ',') "enum",       
       xsda,
       (regexp_matches(xsd_filename,'(?<=AS_)\D+(?=_\d)'))[1] xml_file_prefix
  from arr;

-- Отдельные атрибуты
-- Собирается нормализованное представление
create or replace view xsd.transport_attributes as
with attr as (
select xsd_id,
       loading_session_id,
       tstamp,
       xsd_filename,
       root_node,       
       transport_attribute,
       "name" "name0",
       coalesce(type1, type2) xsd_dt,
       "not null" "usage",
       case when "not null" = 'required' then true
            when "not null" = 'optional' then false
            else null
        end "not null",
       case when "enum" = '0,1' and type2 = 'xs:integer' then 'boolean'
            when type2 = 'xs:integer' and "cardinality" = 2 then 'smallint'
            when type2 = 'xs:long' and "cardinality" = 2 then 'smallint'
            when type2 = 'xs:string' and "length" = 36 then 'uuid'
            when type2 = 'xs:string' then 'varchar'
            when type2 = 'xs:long' and "cardinality" = 19 then 'bigint'
            when type1 = 'xs:date' then 'date'
            when type1 = 'xs:long' then 'bigint'
            when type2 = 'xs:integer' then 'int'
            when type1 = 'xs:boolean' then 'boolean'
            when type1 = 'xs:integer' then 'int'
            when type1 is null and type2 is null then 'varchar'            
            else null
            end "type",
       "cardinality",
       "length",
       xsda,
       table_name,
       t.xml_file_prefix
  from xsd.xsd_attributes a
  full join xsd.table_names t
    on a.xml_file_prefix = t.xsd_file_pefix  
)
select xsd_id,
       loading_session_id,
       tstamp,
       xsd_filename,
       root_node,
       row_number() over (partition by xsd_id, xml_file_prefix) "№",
       transport_attribute,
       case when "name0" = 'Дополнительный номер дома 1' and transport_attribute = 'ADDNUM2' then 'Дополнительный № дома 2'
       else 
       trim(
       (regexp_split_to_array(
       (regexp_split_to_array(
       replace(
       replace(
       replace(
       replace(
       replace(
       replace(
       replace(
       replace(
       replace(
       replace(
       replace(
       replace( "name0", 'Глобальный уникальный идентификатор', 'Код'),
                         'Идентификатор записи связывания', 'Код'),
                         'Уникальный идентификатор записи. Ключевое поле', 'Ключ'),
                         'адресного объекта', 'адр. об.'),
                         'исторической записью', 'истор. зап.'),
                         'Идентификатор', 'Код'),
                         'Уникальный', 'Уник.'),
                         'нормативн', 'нор-'),
                         'документ', 'д-т'),
                         'аименование', 'аим.'),
                         'Номер', '№'),
                         'номер', '№'),                         
       '–'))[1],
       '\('))[1]
       )
       end column_name,
       xsd_dt,
       "usage",
       "not null",
       "type",
       "cardinality",
       "length",
       xsda,
       "name0",
       table_name,
       xml_file_prefix
  from attr;

-- DDL команды для отдельных строк
create view xsd.row_ddl as
select loading_session_id, root_node, xsd_filename, xml_file_prefix, "№", xsda, '    "' || column_name || '" ' || coalesce(type, 'varchar') || ' ' || case when "not null" then 'not null' else '' end  "ddl"
from xsd.transport_attributes;

-- DDL команды для таблиц целиком
create view xsd.table_ddl as 
with att as ( 
select root_node, xsd_filename, xml_file_prefix, array_to_string(array_agg("ddl"), ',
') "ddl"
 from xsd.row_ddl
 group by loading_session_id, xsd_filename, root_node, xml_file_prefix
 )
 select xsd_filename, xsd_id,
        '-- ' || xsd_filename || '
CREATE TABLE "' || current_setting('ГАР.схема', false) || '"."' || table_name || '" (
' || ddl || '
);' ddl
   from att 
   full join xsd.transport_files
  using (root_node, xsd_filename, xml_file_prefix);
