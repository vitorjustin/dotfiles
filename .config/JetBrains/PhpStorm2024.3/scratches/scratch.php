<?php

use Illuminate\Support\Facades\File;
use Spatie\SimpleExcel\SimpleExcelReader;

$filepath = storage_path('EQUIPE_NEORAMA_2023 - EQUIPE NEORAMA 2023.csv');

if (! File::exists($filepath)) {
    throw new Exception('O arquivo de importação não foi localizado em: '.$filepath);
}

$fileReader = SimpleExcelReader::create($filepath);

$this->sheetRows = $fileReader->getRows()->collect();