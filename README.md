# GTAVIral — AI Content Studio

Instalador oficial do **GTAVIral** para **Mac** com chip Apple (M1 ou mais novo) e **Windows 10/11** (64 bits).

## Mac — instalar ou atualizar

Abra o **Terminal** (⌘ Espaço → “Terminal”), cole e aperte Enter:

```bash
curl -fsSL https://raw.githubusercontent.com/dayvth/gtaviral/main/install.sh | bash
```

Voz local grátis com mais naturalidade (baixa ~3 GB a mais):

```bash
curl -fsSL https://raw.githubusercontent.com/dayvth/gtaviral/main/install.sh | bash -s -- --voz-local
```

O instalador baixa o motor, o FFmpeg e o aplicativo, confere a integridade de cada arquivo (SHA-256) e instala tudo em
`~/Library/Application Support/GTAVIral` e na pasta Aplicativos. Rodar de novo atualiza sem apagar seus projetos e chaves.

## Windows — instalar ou atualizar

Abra o **PowerShell** (tecla Windows → digite “PowerShell”), cole e aperte Enter:

```powershell
irm https://raw.githubusercontent.com/dayvth/gtaviral/main/install.ps1 | iex
```

Com a voz local grátis (baixa ~3 GB a mais):

```powershell
& ([scriptblock]::Create((irm https://raw.githubusercontent.com/dayvth/gtaviral/main/install.ps1))) -VozLocal
```

O app fica no menu Iniciar. Seus projetos e chaves ficam em `%APPDATA%\GTAVIral`.

## Requisitos

- Mac com chip Apple (M1+) ou Windows 10/11 64 bits; 15 GB livres; 16 GB de RAM recomendado
- Internet para instalar, pesquisar notícias e usar IAs na nuvem

O passo a passo completo (conectar Gemini, ElevenLabs, YouTube, piloto automático e postagem) está no **guia em PDF**
entregue na compra.

---

GTAVIral é uma ferramenta independente, sem afiliação, patrocínio ou aprovação da Rockstar Games ou da Take-Two
Interactive. “Grand Theft Auto” e “GTA” são marcas de seus respectivos titulares. © GTAVIral — todos os direitos reservados.
