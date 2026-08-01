import urllib.request
import json
import os
import subprocess

connection_string = "postgresql://postgres:barberia-app2026@db.jzrfejjtljdfegvcthpm.supabase.co:5432/postgres"
output_file = r"C:\Users\USUARIO\Documents\UNIVERSIDAD\proyectos_Personales\mi-proyecto-barberia\supabase\migraciones\0000_esquema_live_oficial.sql"

psql_path = r"C:\Program Files\PostgreSQL\17\bin\psql.exe"

command = [
    psql_path,
    connection_string,
    "-c",
    "SELECT table_name FROM information_schema.tables WHERE table_schema = 'public' ORDER BY table_name;"
]

result = subprocess.run(command, capture_output=True, text=True)
print("Tablas encontradas en Supabase:")
print(result.stdout)
