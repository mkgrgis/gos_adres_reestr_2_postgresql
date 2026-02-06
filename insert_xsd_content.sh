#!/bin/bash
[ ! -d "$1" ] && echo 'Первый параметр - каталог с распакованными xsd' && exit;
[ -z "$2" ] && echo 'Второй параметр - условный номер сессии загрузки xsd' && exit;
[ -z "$PGPASSWORD" ] && echo 'Не заполнен пароль PostgreSQL';

# Loop through each XML file in the gar_schemas directory
for xsd_file in "$1"/*.xsd; do
    # Get the filename without the path
    filename=$(basename "$xsd_file")

    # Read the content of the XSD file
    xml_content=$(<"$xsd_file")

    # Insert into the PostgreSQL table
    psql -c "
        INSERT INTO xsd.official_data (xsd_filename, xsd, loading_session_id)
        VALUES ('$filename', '$xml_content', $2);
    "
done
