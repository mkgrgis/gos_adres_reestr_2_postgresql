
absolute_path=$(readlink -f "$1");
fn=$(basename "$absolute_path");
crt=$(echo "select * from xsd.program_call_parameters where xml_file_prefix = ((regexp_match('$fn', '(?<=(^|/)AS_)\D+(?=_\d)'))[1])" | psql -tA);
tc=$(echo "$crt" | cut -f 1 -d '|');
txml=$(echo "$crt" | cut -f 2 -d '|');
tpar=$(echo "$crt" | cut -f 3 -d '|');
echo "Загрузка в таблицу $tc
данные из файла $txml
параметры вызова $tpar";
sh -c "./гар_xml2csv -x '$1' $tpar -i 20000 ";
