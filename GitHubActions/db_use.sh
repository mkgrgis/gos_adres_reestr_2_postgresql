export PGPASSWORD='1234567890';
export PGDATABASE='Государственный адресный реестр';
export PGUSER='Государственный адресный реестр';
export PGPORT=5432;
export PGHOST=127.0.0.1;
# Пример загрузки скрипта SQL создающего схему и струтуру для метаданных
cat sql/xsd.sql | psql -e;
# Пример запуска первой сессии загрузки метаданных, можно передать иной адре источника XSD чем по умолчанию из ФНС
./load_xsd.sh "$1";

ddf='sql/ГАР_pgDDL.sql';
echo "select 'CREATE SCHEMA \"' || set_config('ГАР.схема', 'data', false) ||'\";'; select ddl from xsd.table_ddl;" | psql -Atq > "$ddf";
# Прочитать сгенерированное
echo "Автоматический скрипт, расшифровка загруженных XSD
----------------------------------------------------------------------------"
cat "$ddf";
export PGPASSWORD=\'\';
