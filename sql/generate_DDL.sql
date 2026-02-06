select * from xsd.transport_files;
select * from xsd.transport_attributes;

-- Генерация выражений ЯОД/DDL
select 'CREATE SCHEMA IF NOT EXIST "' || set_config('ГАР.схема', 'data', false) ||'";';
select * from xsd.table_ddl;
select ddl from xsd.table_ddl;

select * from xsd.row_ddl;

create view xsd.data_files_prefix as
select *,
       ((regexp_match(fileaddress, '^\d+(?=/)'))[1])::varchar "Регион",
       ((regexp_match(fileaddress, '(?<=(^|/))\D+(?=_\d)'))[1])::varchar "Префикс",
       ((regexp_match(fileaddress, '(?<=(^|/)\D+_)\d+'))[1])::date "Префикс даты",
       ((regexp_match(fileaddress, '(?<=(^|/)\D+_\d+_)[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}'))[1])::uuid "uuid"
from xsd.ziped_xml_files zf;