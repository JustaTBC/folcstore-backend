# PI4-244 - Cria um banco separado para demonstrar DDL e seed do zero.
# Nao altera nem remove o banco principal 'folcstore'.
# Execute na raiz do repositorio: .\database\av2\preparar_demo.ps1
param(
    [ValidatePattern('^folcstore_av2_demo(?:_[a-z0-9]+)?$')]
    [string]$Database = 'folcstore_av2_demo'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$arquivos = @(
    'ddl.sql',
    'seed_dml.sql',
    'verificar_modelo.sql',
    'verificar_povoamento.sql',
    'testes_povoamento.sql',
    'erro_check_visivel.sql',
    'erro_fk_visivel.sql'
)

Push-Location $repoRoot
try {
    foreach ($arquivo in $arquivos) {
        if (-not (Test-Path (Join-Path 'database\av2' $arquivo))) {
            throw "Arquivo ausente: database/av2/$arquivo. Confira as entregas PI4-242/243."
        }
    }
    if (-not (Test-Path '.env.postgres')) {
        throw 'Arquivo .env.postgres ausente. Configure a PI4-241 antes de continuar.'
    }
    if (-not (Test-Path 'compose.postgres.yaml')) {
        throw 'Arquivo compose.postgres.yaml ausente.'
    }

    $dockerCmd = Get-Command docker -ErrorAction SilentlyContinue
    if ($null -ne $dockerCmd) {
        $dockerExe = $dockerCmd.Source
    } elseif (Test-Path 'C:\Program Files\Docker\Docker\resources\bin\docker.exe') {
        $dockerExe = 'C:\Program Files\Docker\Docker\resources\bin\docker.exe'
    } else {
        throw 'Docker nao encontrado. Inicie o Docker Desktop e confira a instalacao.'
    }

    $compose = @('compose', '--env-file', '.env.postgres', '-f', 'compose.postgres.yaml')

    & $dockerExe @compose 'exec' '-T' 'postgres' 'psql' '-U' 'folcstore' '-d' 'postgres' '-tAc' 'SELECT 1;' | Out-Null
    if ($LASTEXITCODE -ne 0) { throw 'O PostgreSQL nao esta acessivel. Execute docker compose up -d postgres.' }

    $query = "SELECT 1 FROM pg_database WHERE datname = '$Database';"
    $consulta = & $dockerExe @compose 'exec' '-T' 'postgres' 'psql' '-U' 'folcstore' '-d' 'postgres' '-tAc' $query
    if ($LASTEXITCODE -ne 0) { throw 'Falhou a verificacao do banco de demonstracao.' }
    if (([string]($consulta -join '')).Trim() -eq '1') {
        throw "O banco $Database ja existe. Nao sera sobrescrito. Use -Database folcstore_av2_demo_2 (outro nome)."
    }

    Write-Host "Criando banco isolado $Database (sem tabelas)..."
    & $dockerExe @compose 'exec' '-T' 'postgres' 'psql' '-U' 'folcstore' '-d' 'postgres' '-v' 'ON_ERROR_STOP=1' '-c' "CREATE DATABASE $Database;"
    if ($LASTEXITCODE -ne 0) { throw 'Falha ao criar o banco isolado.' }

    foreach ($arquivo in $arquivos) {
        $origem = "database/av2/$arquivo"
        $destino = "postgres:/tmp/pi4244_$arquivo"
        & $dockerExe @compose 'cp' $origem $destino
        if ($LASTEXITCODE -ne 0) { throw "Falha ao copiar $arquivo para o container." }
    }

    Write-Host ''
    Write-Host "SUCESSO: $Database esta VAZIO e os scripts foram copiados para o conteiner." -ForegroundColor Green
    Write-Host 'O banco original folcstore nao foi modificado.'
    Write-Host "No video, execute o DDL e o seed com -d $Database, conforme README_PI4-244.md."
} finally {
    Pop-Location
}
