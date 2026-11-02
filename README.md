# ENEM 2023: nota de Matemática por cor/raça, renda familiar e tipo de escola

Scripts em Python e em sintaxe do IBM SPSS Statistics para analisar a nota da prova de Matemática do ENEM 2023 segundo a cor/raça, a faixa de renda familiar e o tipo de escola do Ensino Médio. O conjunto cobre desde a montagem do banco de dados a partir dos microdados do INEP até a análise descritiva e o cálculo do tamanho do efeito.

## Conteúdo

| Arquivo | O que faz |
|---|---|
| `ENEM2023_00_Gerar_Banco_SPSS.py` | Lê os microdados e o arquivo de itens do INEP, aplica o recorte da análise e grava o banco `.sav` com as respostas de Matemática reordenadas para um único caderno de referência. |
| `ENEM2023_01_Tamanho_do_Efeito.sps` | ANOVA de uma via, eta quadrado, ômega quadrado e d de Cohen entre todos os pares de grupos. Inclui um modelo com as três variáveis juntas (ANOVA fatorial, soma de quadrados tipo III). Produz 9 tabelas. |
| `ENEM2023_02_Descritiva_Cor_Raca.sps` | Análise descritiva da nota por cor/raça: perfil de cada grupo, médias, medianas, percentis, distribuição por faixas de nota e quartis, quadro-síntese e comparações dentro de renda, tipo de escola, escolaridade dos pais e sexo. Produz 25 tabelas e 4 gráficos. |
| `ENEM2023_03_Descritiva_Renda.sps` | Mesma estrutura descritiva, com a faixa de renda familiar como grupo de comparação. Produz 11 tabelas e 1 gráfico. |
| `ENEM2023_04_Descritiva_Tipo_de_Escola.sps` | Mesma estrutura descritiva, com o tipo de escola (pública ou privada) como grupo de comparação. Produz 11 tabelas e 1 gráfico. |

## Requisitos

- Python 3 com `pandas`, `numpy` e `pyreadstat`:
  ```
  pip install pandas numpy pyreadstat
  ```
- IBM SPSS Statistics. As sintaxes são compatíveis com a versão 22.
- Os arquivos `MICRODADOS_ENEM_2023.csv` e `ITENS_PROVA_2023.csv`, divulgados pelo INEP. **Os dados não estão incluídos neste repositório.**

## Como usar

1. Coloque `MICRODADOS_ENEM_2023.csv` e `ITENS_PROVA_2023.csv` na mesma pasta.
2. Gere o banco `.sav`:
   ```
   python ENEM2023_00_Gerar_Banco_SPSS.py MICRODADOS_ENEM_2023.csv
   ```
   O resultado padrão é `enem_2023_MT_caderno_azul.sav`, acompanhado de um arquivo `_correspondencia_itens.csv` com a posição de cada item em cada caderno, para conferência.
   Opções úteis:
   - `--itens CAMINHO` indica o arquivo de itens, caso não esteja na pasta do CSV de entrada.
   - `-o ARQUIVO.sav` define o nome do arquivo de saída.
   - `--zsav` grava o arquivo comprimido (exige SPSS 21 ou mais novo).
   - `--branco-missing` trata a resposta em branco como missing em `ACERTO_RMT_*`, em vez de erro.
   - `--ignorar-divergencia` apenas avisa, em vez de interromper, se o gabarito reordenado divergir do de referência.
3. Abra o `.sav` no SPSS, abra uma das sintaxes (`.sps`) e execute tudo (*Run > All*).
4. Cada sintaxe é independente das demais. O cabeçalho de cada uma traz a lista de tabelas, as variáveis criadas e as regras aplicadas.

## O que o script Python faz

1. Lê o CSV dos microdados e mantém apenas as colunas necessárias.
2. Filtra os alunos presentes na prova de Matemática, que não são treineiros e concluem o Ensino Médio em 2023.
3. Confere que os cadernos 1211 (Azul), 1212 (Amarela), 1213 (Rosa) e 1214 (Cinza) têm os mesmos 45 itens de Matemática e o mesmo gabarito item a item. Se algum não passar, o script para.
4. Reordena as respostas de cada aluno para a ordem do caderno de referência (1211, Azul).
5. Cria `RMT_1` a `RMT_45` (resposta), `GMT_1` a `GMT_45` (gabarito) e `ACERTO_RMT_1` a `ACERTO_RMT_45`. Nos itens anulados, o acerto fica como missing.
6. Grava o `.sav` com formatos, rótulos de variável e rótulos de valor. A coluna `CO_PROVA_MT` mantém o caderno que o aluno de fato fez, e `TX_RESPOSTAS_MT_ORIG` guarda as respostas como vieram no CSV.

## Amostra analisada nas sintaxes

Concluintes de 2023 presentes na prova de Matemática, sem treineiros, com cor/raça declarada (Branca, Preta, Parda, Amarela ou Indígena), tipo de escola, sexo, renda e escolaridade dos pais informados, e nota maior que zero. As quatro sintaxes usam exatamente a mesma amostra, então os resultados podem ser comparados entre si.

## Faixas de renda familiar

Construídas a partir da variável `Q006`. SM = salário mínimo (R$ 1.320 em 2023).

| Faixa | Códigos de `Q006` |
|---|---|
| Até 1 SM | A, B |
| 1 a 1,5 SM | C |
| 1,5 a 2 SM | D |
| 2 a 2,5 SM | E |
| 2,5 a 3 SM | F |
| 3 a 4 SM | G |
| 4 a 5 SM | H |
| Mais de 5 SM | I a Q |

## Medidas usadas

- **d de Cohen:** diferença entre as médias de dois grupos dividida pelo desvio padrão combinado. Referências de Cohen: 0,2 pequeno, 0,5 médio, 0,8 grande.
- **Eta quadrado:** proporção da variância da nota explicada pela variável. O ômega quadrado é a versão com menos viés. Referências de Cohen: 0,01 pequeno, 0,06 médio, 0,14 grande.
- **Eta quadrado parcial e variância exclusiva:** efeito de cada variável controlando as outras duas, e a parte da variância total que só ela explica.
- **Percentis:** método da média ponderada (definição 1), o padrão do SPSS.
- **Número mínimo de alunos:** na sintaxe de cor/raça, médias, medianas e percentuais por célula só aparecem com 100 ou mais alunos; as demais mostram "n baixo".

## Dados

Os microdados do ENEM 2023 e o arquivo de itens da prova são públicos e podem ser obtidos no site do INEP. Eles não são incluídos aqui por causa do tamanho e para que cada pessoa use a versão oficial.
