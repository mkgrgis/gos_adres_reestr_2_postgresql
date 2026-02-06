export PGPASSWORD='1234567890';
export PGDATABASE='Государственный адресный реестр';
export PGUSER='Государственный адресный реестр';
export PGPORT=5432;
export PGHOST=127.0.0.1;

mkdir test/result;

echo "ФАЙЛЫ ГАР
----------------------------------------------------------------------------"
echo "select "№", xsd_id, loading_session_id, tstamp, xsd_filename, xml_file_prefix, table_name, root_node, singular_transport_node, xsd_descr_general, xsd_descr_singular
from xsd.transport_files;" | psql > test/result/files.out;
diff test/expected/files.out test/result/files.out > test/files.diff;
[ $? -eq 0 ] && echo "Успешно";
echo "АТРИБУТЫ ГАР
----------------------------------------------------------------------------"
echo "select xsd_id, loading_session_id, tstamp, xsd_filename, root_node, "№", transport_attribute, column_name, xsd_dt, "usage", "not null", "type", "cardinality", length, name0, table_name, xml_file_prefix
from xsd.transport_attributes;" | psql > test/result/att.out;
diff test/expected/att.out test/result/att.out > test/att.diff;
[ $? -eq 0 ] && echo "Успешно";

ddf='sql/ГАР_pgDDL.sql';
cat "$ddf" | psql -e > test/result/ddl.out || true;
diff test/expected/ddl.out test/result/ddl.out > test/ddl.diff;
[ $? -eq 0 ] && echo "Успешно";
