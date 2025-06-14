#!/bin/bash

# Проверка аргументов
if [ "$#" -ne 3 ]; then
    echo "Использование: $0 <директория> <старый_текст> <новый_текст>"
    exit 1
fi

directory="$1"
old_text="$2"
new_text="$3"

# Проверка существования директории
if [ ! -d "$directory" ]; then
    echo "Ошибка: Директория '$directory' не существует."
    exit 1
fi

# Функция для замены текста в файлах
replace_in_files() {
    local file="$1"
    # Заменяем текст только в обычных файлах (не директориях, не симлинках и т.д.)
    if [ -f "$file" ]; then
        echo "Обработка содержимого файла: $file"
        # Используем временный файл для безопасной замены
        temp_file=$(mktemp)
        sed "s/$old_text/$new_text/g" "$file" > "$temp_file"
        mv "$temp_file" "$file"
    fi
}

# Функция для переименования файлов и директорий
rename_files_and_dirs() {
    local path="$1"
    local dir=$(dirname "$path")
    local base=$(basename "$path")
    
    # Если имя содержит старый текст, переименовываем
    if [[ "$base" == *"$old_text"* ]]; then
        local new_base="${base//$old_text/$new_text}"
        local new_path="$dir/$new_base"
        
        # Переименовываем только если новый путь не существует
        if [ ! -e "$new_path" ]; then
            echo "Переименование: '$path' -> '$new_path'"
            mv "$path" "$new_path"
            path="$new_path"
        else
            echo "Предупреждение: '$new_path' уже существует, пропускаем."
        fi
    fi
    
    # Если это директория, рекурсивно обрабатываем её содержимое
    if [ -d "$path" ]; then
        for item in "$path"/*; do
            [ -e "$item" ] || continue
            rename_files_and_dirs "$item"
        done
    else
        replace_in_files "$path"
    fi
}

# Начинаем обработку с корневой директории
echo "Начало обработки директории: $directory"
for item in "$directory"/*; do
    [ -e "$item" ] || continue
    rename_files_and_dirs "$item"
done
chmod -R 777 $1
echo "Обработка завершена."