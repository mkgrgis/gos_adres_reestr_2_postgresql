#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <libxml/SAX.h>
#include <unistd.h>
#include <time.h>

#include "common.h"

int read_xmlfile(FILE *f);
xmlSAXHandler make_sax_handler();
struct timespec ts_before, ts_after, ts_diff;

/* SAX GROUP */

void SAX_startElementNs(void *ctx, const xmlChar *localname, const xmlChar *prefix, const xmlChar *URI, int nb_namespaces, const xmlChar **namespaces, int nb_attributes, int nb_defaulted, const xmlChar **attributes);
void SAX_endElementNs(void *ctx, const xmlChar *localname, const xmlChar *prefix, const xmlChar *URI);
static void SAX_OnCharacters(void *ctx, const xmlChar *ch, int len);
#define UNUSED(x) (void)(x)

static char**	selected_attributes = NULL;
static char*	xpath_prefix = NULL;
static int		cortage_count = 0;
static int		info_cortage_step = 0;
static char		csv_row[PG_COPY_BUFFER_SIZE];

void SAX_startElementNs(void *ctx, const xmlChar *localname, const xmlChar *prefix, const xmlChar *URI, int nb_namespaces, const xmlChar **namespaces, int nb_attributes, int nb_defaulted, const xmlChar **attributes)
{
	UNUSED(prefix);
	UNUSED(URI);
	UNUSED(namespaces);
	UNUSED(nb_namespaces);
	UNUSED(nb_defaulted);
	SAX_Context *context = (SAX_Context *)ctx;

	// Build the current path
	if (context->currentPath ) {
		char *newPath = malloc(strlen(context->currentPath) + strlen((const char *)localname) + 2);
		sprintf(newPath, "%s/%s", context->currentPath, localname);
		free(context->currentPath);
		context->currentPath = newPath;
	} else {
		context->currentPath = strdup((const char *)localname);
	}

	// fprintf(stderr, " el->: %s\n", context->currentPath);

	if (strcmp(context->currentPath, xpath_prefix)) {
		fprintf(stderr, "Нелинейный элемент: %s\n", context->currentPath);
		return;
	}
	cortage_count++;

	// printf("Start element: %s, n s ", context->currentPath, localname);

	AttrMap** am = (AttrMap**) malloc(sizeof(AttrMap*) * nb_attributes + 1);
	am[nb_attributes] = NULL;

	// Loop through the attributes
	const int fields = 5;	// (localname/prefix/URI/value/end)

	for (int i = 0; i < nb_attributes; i++) {
		const xmlChar *a_localname = attributes[i * fields + 0];
		// const xmlChar *a_prefix = attributes[i * fields + 1];
		// const xmlChar *a_URI = attributes[i * fields + 2];
		const xmlChar *a_value_start = attributes[i * fields + 3];
		const xmlChar *a_value_end = attributes[i * fields + 4];
		size_t a_size = a_value_end - a_value_start;
		xmlChar *a_value = (xmlChar *) malloc(sizeof(xmlChar) * a_size + 1);
		memcpy(a_value, a_value_start, a_size);
		a_value[a_size] = '\0';
		AttrMap * m = (AttrMap*) malloc(sizeof(AttrMap));
		m->name = a_localname;
		m->value = a_value;
		am[i] = m;
	}

	int att_i = 0;
	csv_row[0] = '\0';
	while (selected_attributes[att_i] != NULL)
	{
		const char * sa = selected_attributes[att_i];
		att_i++;
		// Разделитель печатается даже для не заполняемых атрибутов
		if (att_i > 1)
			sprintf(csv_row + strlen(csv_row), "\t");
		// Если атрибут таблицы ничем не заполняется, в XML атрибуте ничего не указано, то просто пропустим его
		if (sa[0] == '\0')
			continue;
		// Сравним названия нужного атрибута XML поставляющего данные в таблицу со всеми ранее запасёнными
		for (int i = 0; i < nb_attributes; i++) {
			AttrMap * m = am[i];
			if (strcmp(sa, (const char *)m->name) == 0)
			{
				sprintf(csv_row + strlen(csv_row), "\"%s\"", m->value);
			}
		}
	}
	sprintf(csv_row + strlen(csv_row), "\n");

	pg_cortage_copy_send_row(context, csv_row);
//	printf (csv_row);

	AttrMap_free (am, nb_attributes);

	if ((cortage_count % info_cortage_step) == 0)
	{
		printf("%d\n", cortage_count);
	}
}

void SAX_endElementNs(void *ctx, const xmlChar *localname, const xmlChar *prefix, const xmlChar *URI)
{
	UNUSED(localname);
	UNUSED(prefix);
	UNUSED(URI);
	SAX_Context *context = (SAX_Context *)ctx;

	// Free the current path (backtrack)
	if (context->currentPath) {
		char *lastSlash = strrchr(context->currentPath, '/');
		if (lastSlash) {
			*lastSlash = '\0'; // Backtrack
		} else {
			free(context->currentPath);
			context->currentPath = NULL;
		}
	}
}

static void SAX_OnCharacters(void *ctx, const xmlChar *ch, int len)
{
	UNUSED(ctx);
	UNUSED(ch);
	UNUSED(len);
}

static xmlSAXHandler saxHandler = {
    .initialized = XML_SAX2_MAGIC, /* signal SAX2 */
    .startElementNs = SAX_startElementNs,
    .endElementNs = SAX_endElementNs,
    .characters = SAX_OnCharacters,
    /* other callbacks left NULL */
};

/* SAX end */

void showhelp(char * name) {
	printf("Вызов: %s [настройки] \n\n", name);
	printf("настройки:\n");
	printf("\t-x\tАдрес разбираемого XML файла в файловой системе\n");
	printf("\t-p\tПрефикс линейного элемента данных в формате A1/A2/A3\n");
	printf("\t-t\tТаблица PostgreSQL, получающая загружаемые из XML файла данные\n");
	printf("\t-a\tСписок свойств линейного узла XML, помещаемых в таблицу.\n\t\t\tУпорядочивается в порядке полей таблицы, должен совпась с ними по количеству\n");
	printf("\t-i\tШаг печати информации о занесении кортежей, каждый кортеж по умолчанию\n");
	printf("\t-h\tПоказать эту справку\n\n");
	printf("\t-h\tПример:\n%s \\ \n -a 'ID,OBJECTID,OBJECTGUID,CHANGEID,HOUSENUM,ADDNUM2,ADDNUM1,HOUSETYPE,ADDTYPE1,ADDTYPE2,OPERTYPEID,PREVID,NEXTID,UPDATEDATE,STARTDATE,ENDDATE,ISACTUAL,ISACTIVE' \\ \n -t '\"public\".\"№ домов улиц населённых пунктов\"' \\\n -p 'HOUSES/HOUSE' \\\n -x 'Государственный адресный реестр/XML за 2026-01-29/AS_HOUSES_20251215_55004bba-fe23-4aeb-8eba-ebc086b8a94c.XML'", name);
	printf("\n");
}

int main(int argc, char *argv[])
{
	char * xml_file_address = NULL;
	char * pg_table_name = NULL;
	char c;

	while ((c = getopt (argc, argv, "ha:p:x:t:i:")) != -1)
	{
		switch (c) {
			case 'h':
				showhelp(argv[0]);
				return EXIT_SUCCESS;
			case 'a':
				selected_attributes = str_split(optarg, ',');
				break;
			case 'p':
				xpath_prefix = optarg;
				break;
			case 'x':
				xml_file_address = optarg;
				break;
			case 't':
				pg_table_name = optarg;
				break;
			case 'i':
				info_cortage_step = atoi(optarg);
				break;
			default:
				break;
		}
	}

	if (xml_file_address == NULL) {
		fprintf(stderr,"Файл XML для обработки не задан (параметр -x)\n");
		exit(1);
	}
	if (xpath_prefix == NULL) {
		fprintf(stderr,"Префикс линейного элемента данных не задан (параметр -p)\n");
		exit(1);
	}
	if (selected_attributes == NULL) {
		fprintf(stderr,"Список нужных для переноса в CSV свойств линейного элемента данных не задан (параметр -a)\n");
		exit(1);
	}
	if (pg_table_name == NULL) {
		fprintf(stderr,"Таблица PostgreSQL получающая данные задана (параметр -t)\n");
		exit(1);
	}

	char* password = getenv("PGPASSWORD");
	if (password == NULL) {
		fprintf(stderr,"Пароль в переменной окружения PGPASSWORD не задан! Будьте внимательны к ошибкам отказа в доступе\n");
	}

	// Connect to the database
	const char* pghost = getenv("PGHOST");
	const char* pgport = getenv("PGPORT");
	const char* dbname = getenv("PGDATABASE");
	const char* pguser = getenv("PGUSER");
	const char* pgoptions = NULL;
	PGconn *conn = PQsetdbLogin(pghost, pgport, pgoptions, NULL, dbname, pguser, password);

	// Check if the connection was successful
	if (PQstatus(conn) != CONNECTION_OK) {
		fprintf(stderr, "Ошибка соединения с БД: %s\n", PQerrorMessage(conn));
		PQfinish(conn);
		return 1;
	}

	xmlInitParser();
	SAX_Context context;
	context.pgCopyStatus.conn = conn;
	context.pgCopyStatus.offset = 0;
	context.currentPath = NULL;

	FILE *f = fopen(xml_file_address, "r");
	if (!f) {
		fprintf(stderr,"Ошибка открытия указанного файла.\n");
		exit(1);
	}
	fclose(f);

	// Начало транзакции
	PGresult *res = PQexec(conn, "BEGIN");
	PQclear(res);

	// Инициализация COPY
	if (pg_cortage_copy_begin(conn, pg_table_name) < 0) {
		PQfinish(conn);
		fprintf(stderr,"Ошибка инициализации буфера для ввода в БД.\n");
		exit(1);
	}

	// fprintf(stderr, "... Соединено с БД, файл XML доступен: %s Буфер ввода в БД настроен: %s %s\n", xml_file_address, pg_table_name, xpath_prefix);

	ts_diff.tv_sec  = 0;
	ts_diff.tv_nsec = 0;
	clock_gettime(CLOCK_REALTIME, &ts_before);

	if (xmlSAXUserParseFile(&saxHandler, &context, xml_file_address) != 0) {
        fprintf(stderr,"Ошибка разбора xml.\n");
        xmlCleanupParser();
        return 2;
    }

	// Опустошение структур разбора файла XML
	free(context.currentPath);
	xmlCleanupParser();

	printf("\n");

	// Завершение работы с БД
	if (pg_cortage_copy_end(&context) < 0) {
		PQexec(conn, "ROLLBACK");
		PQfinish(conn);
		return 1;
	}
	// Коммит
	res = PQexec(conn, "COMMIT");
	PQclear(res);
	PQfinish(conn);

	// Показ общего времени операции
	clock_gettime(CLOCK_REALTIME, &ts_after);
	timespec_diff(&ts_after, &ts_before, &ts_diff);
	fprintf(stderr,"Всего завершено за: %lf секунд\n%d кортежей\n", ts_diff.tv_sec + (ts_diff.tv_nsec/1000000000.0), cortage_count);
	return EXIT_SUCCESS;
}
