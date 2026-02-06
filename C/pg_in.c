#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>

#include "common.h"

#define MAX_URL_LEN 4006

// Инициализация COPY-сессии
int pg_cortage_copy_begin(PGconn *conn, const char *table_name)
{
	char query[256];
	snprintf(query, sizeof(query), "COPY %s FROM STDIN WITH CSV DELIMITER E'\\t'", table_name);

	PGresult *res = PQexec(conn, query);
	if (PQresultStatus(res) != PGRES_COPY_IN) {
		fprintf(stderr, "COPY failed: %s\n", PQerrorMessage(conn));
		PQclear(res);
		return -1;
	}
	PQclear(res);
	return 0;
}

// Отправка данных (буферизованная)
int pg_cortage_copy_send_row(SAX_Context *state, const char *csv_row)
{
	size_t row_len = strlen(csv_row);

	// Если строка не влезает, сбрасываем буфер
	if (state->pgCopyStatus.offset + row_len >= PG_COPY_BUFFER_SIZE) {
		if (PQputCopyData(state->pgCopyStatus.conn, state->pgCopyStatus.buffer, state->pgCopyStatus.offset) <= 0) {
			fprintf(stderr, "PQputCopyData failed: %s\n", PQerrorMessage(state->pgCopyStatus.conn));
			return -1;
		}
		state->pgCopyStatus.offset = 0;
	}

	// Копируем строку в буфер
	memcpy(state->pgCopyStatus.buffer + state->pgCopyStatus.offset, csv_row, row_len);
	state->pgCopyStatus.offset += row_len;

	return 0;
}

// Завершение COPY
int pg_cortage_copy_end(SAX_Context *state)
{
	// Сбрасываем остаток буфера
	if (state->pgCopyStatus.offset > 0) {
		if (PQputCopyData(state->pgCopyStatus.conn, state->pgCopyStatus.buffer, state->pgCopyStatus.offset) <= 0) {
			return -1;
		}
	}

	// Сообщаем серверу о завершении
	if (PQputCopyEnd(state->pgCopyStatus.conn, NULL) <= 0) {
		fprintf(stderr, "PQputCopyEnd failed: %s\n", PQerrorMessage(state->pgCopyStatus.conn));
		return -1;
	}

	// Получаем результат
	PGresult *res = PQgetResult(state->pgCopyStatus.conn);
	if (PQresultStatus(res) != PGRES_COMMAND_OK) {
		fprintf(stderr, "Ошибка при проведении SQL COPY: %s\n", PQresultErrorMessage(res));
		PQclear(res);
		return -1;
	}

	PQclear(res);
	return 0;
}

/*
void insertData(PGconn *conn, AttrMap *attrs, int numAttrs) {
	// Prepare the base SQL statement
	const char *sql = "INSERT INTO your_table_name (column1, column2, column3, column4) VALUES ($1, $2, $3, $4)";

	// Prepare the statement
	PGresult *res = PQprepare(conn, "insert_query", sql, 0, NULL);
	if (PQresultStatus(res) != PGRES_COMMAND_OK) {
		fprintf(stderr, "PREPARE failed: %s", PQerrorMessage(conn));
		PQclear(res);
		return;
	}
	PQclear(res);

	// Create an array for the values to insert
	const char *values[4];
	for (int i = 0; i < numAttrs && i < 4; i++) {
		values[i] = attrs[i].value; // Set up the values
	}

	// Execute the insertion
	res = PQexecParams(conn, "EXECUTE insert_query($1, $2, $3, $4)",
						4,	   // Number of params
						NULL,	// Parameter types (NULL means text)
						values,  // Values
						NULL,	// Lengths (NULL for standard length)
						NULL,	// Formats (NULL for text format)
						0);	  // Result format (0 = text)

	// Check for successful execution
	if (PQresultStatus(res) != PGRES_COMMAND_OK) {
		fprintf(stderr, "INSERT failed: %s", PQerrorMessage(conn));
	} else {
		printf("Data inserted successfully.\n");
	}

	PQclear(res);
}
*/
