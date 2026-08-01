import os
import re

dump_file = r"C:\Users\USUARIO\Documents\UNIVERSIDAD\proyectos_Personales\mi-proyecto-barberia\supabase\migraciones\0000_esquema_completo_live_supabase.sql"
output_dir = r"C:\Users\USUARIO\Documents\UNIVERSIDAD\proyectos_Personales\mi-proyecto-barberia\supabase\sql_editor_queries"

os.makedirs(output_dir, exist_ok=True)

with open(dump_file, "r", encoding="utf-8") as f:
    content = f.read()

# Separate statements by CREATE / ALTER blocks
blocks = re.split(r'(\n--\n-- Name: .*?\n--\n)', content)

queries = []
current_header = ""

for block in blocks:
    if block.startswith("\n--\n-- Name:"):
        current_header = block
    else:
        if current_header and block.strip():
            queries.append(current_header + block)

print(f"Total de bloques extraídos: {len(queries)}")

# Create top 68 clean SQL editor queries
idx = 1
for q in queries:
    if "CREATE TABLE" in q or "CREATE FUNCTION" in q or "CREATE TYPE" in q or "CREATE VIEW" in q:
        match = re.search(r'Name: (.*?);', q)
        name_str = match.group(1).strip().replace(" ", "_").replace("(", "_").replace(")", "") if match else f"query_{idx:02d}"
        filename = f"{idx:02d}_{name_str}.sql"
        filepath = os.path.join(output_dir, filename)
        with open(filepath, "w", encoding="utf-8") as f:
            f.write(q.strip() + "\n")
        idx += 1
        if idx > 68:
            break

print(f"Se crearon {idx-1} archivos en supabase/sql_editor_queries/")
