mkdir test/result;

echo "ФАЙЛЫ ГАР
----------------------------------------------------------------------------"
echo 'select "№", xsd_id, loading_session_id, tstamp, xsd_filename, xml_file_prefix, table_name, root_node, singular_transport_node, xsd_descr_general, xsd_descr_singular
from xsd.transport_files;' | psql > test/result/xml_files.out;
diff test/expected/xml_files.out test/result/xml_files.out > test/xml_files.diff;
[ $? -eq 0 ] && echo "Успешно";
echo "АТРИБУТЫ ГАР
----------------------------------------------------------------------------"
echo 'select xsd_id, loading_session_id, tstamp, xsd_filename, root_node, "№", transport_attribute, column_name, xsd_dt, "usage", "not null", "type", "cardinality", "length", name0, table_name, xml_file_prefix
from xsd.transport_attributes;' | psql > test/result/xml_att.out;
diff test/expected/xml_att.out test/result/xml_att.out > test/xml_att.diff;
[ $? -eq 0 ] && echo "Успешно";

ddf='sql/ГАР_pgDDL.sql';
cat "$ddf" | psql -e > test/result/ddl.out || true;
diff test/expected/ddl.out test/result/ddl.out > test/ddl.diff;
[ $? -eq 0 ] && echo "Успешно";

dct='sql/dict_xml_pg.sql';
cat "$dct" | psql -e > test/result/dict_xml_pg.out || true;
diff test/expected/dict_xml_pg.out test/result/dict_xml_pg.out > test/dict_xml_pg.diff;
[ $? -eq 0 ] && echo "Успешно";
