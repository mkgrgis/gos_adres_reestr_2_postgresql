# Файл сохранения номера загрузочной сессии
gs='.ГАР session';
[ ! -f "$gs"  ] && echo '1' > "$gs";
sess_num0=$(cat "$gs");
# Увеличим № сессии загрузки
sess_num=$(($sess_num0 + 1 ));
# Запишем  № сессии загрузки
echo -n "$sess_num" > "$gs";

# URL адрес скачки файла метаданных
[ ! -z "$1" ] && xsd_official_url="$1";
[ -z "$1" ] && xsd_official_url='https://fias.nalog.ru/docs/gar_schemas.zip';

zip_adr='../gar_schemas.zip'; # Название скачиваемого архива
dir='ГАР xsd'; # Адрес каталога для распаковки файла метаданных
# Скачаем файл метаданных, если его нет
[ ! -f "$zip_adr" ] && wget "$xsd_official_url" -O "$zip_adr";
# Чистка ранее распакованного, жёсткая перезапись временного каталога.
[ -d "$dir" ] && rm -rf "$dir" -v;
mkdir "$dir";
# Распаковка XSD файлов из архива во временный каталог
unzip "$zip_adr" -d "$dir" || exit;
# Загрузка всех распакованных XSD файлов в БД
$(dirname $0)/insert_xsd_content.sh "$dir" "$sess_num";
