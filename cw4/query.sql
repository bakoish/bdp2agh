-- wyświetlenie definicji tabeli w bazie:

--Oracle--------------------------------------------------
DESCRIBE nazwa_tabeli;
--lub
SELECT column_name, data_type, data_length
FROM user_tab_columns
WHERE table_name = 'nazwa_tabeli';



--PostgreSQL--------------------------------------------------
\d nazwa_tabeli
--lub
SELECT column_name, data_type, character_maximum_length
FROM information_schema.columns
WHERE table_name = 'nazwa_tabeli';




--MySQL--------------------------------------------------
DESC nazwa_tabeli;
--lub
SHOW COLUMNS FROM nazwa_tabeli;

