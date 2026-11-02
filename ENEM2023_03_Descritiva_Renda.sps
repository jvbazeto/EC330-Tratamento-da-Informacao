* Encoding: UTF-8.
* =====================================================================.
* ENEM 2023 - NOTA DE MATEMÁTICA E RENDA FAMILIAR: PACOTE ESSENCIAL (BLOCOS 1 A 5).
* Análise descritiva simples: médias, medianas, percentis, frequências e proporções.
* Nenhum teste de hipótese ou modelo estatístico é solicitado. Compatível com SPSS 22.
* O grupo de comparação é a faixa de renda familiar (renda8); a cor/raça entra no perfil de cada faixa.
* =====================================================================.
*
* COMO USAR.
* 1) Abra o banco .sav completo (File > Open > Data) e deixe-o como conjunto ativo.
* 2) Abra este arquivo (File > Open > Syntax) e rode tudo (Run > All).
*
* O QUE O PACOTE PRODUZ (11 tabelas e 1 gráfico).
*   Bloco 1  Quem entra na análise: 1 tabela (fluxo de seleção).
*   Bloco 2  Perfil de cada faixa de renda: 4 tabelas (escola, cor/raça, escolaridade dos pais, sexo).
*   Bloco 3  Nota por faixa de renda: 3 tabelas (média e mediana; cortes gerais; percentis por grupo) + boxplot.
*   Bloco 4  Distribuição das notas entre as faixas de renda: 2 tabelas (faixas de nota e quartis).
*   Bloco 5  Quadro-síntese: 1 tabela, com uma linha por faixa de renda (alunos, nota média, pontos abaixo da referência,
*            % entre os 25% maiores e menores notas e a razão entre esses percentuais e os da referência).
*
* CASAS DECIMAIS (padrão: 3).
*   Médias, medianas, percentis, diferenças, percentuais calculados e razões saem todos com 3 casas decimais (ex.: 569,303).
*   Tabelas automáticas do SPSS (bloco 3): o SPSS 22 exibe estas estatísticas com 2 casas a mais que o formato da variável.
*   Como NU_NOTA_MT tem formato F8.1 (seção 1.6), elas saem com 3 casas.
*   Tabelas montadas no script (blocos 3.3 e 5): usam o formato !fmt (F9.3), definido na seção 0.
*   Para usar 4 casas em tudo: na seção 0, troque F8.1 por F8.2 em !fmtnota e F9.3 por F9.4 em !fmt.
*   Contagens de alunos são sempre inteiras. Os percentuais dos CROSSTABS (blocos 2 e 4) e do FREQUENCIES do bloco 1
*   são impressos pelo SPSS com 1 casa decimal (formato fixo desses comandos) e não mudam com este padrão.
*
* AMOSTRA ANALISADA (variável amostra_A = 1).
*   Concluintes de 2023 presentes na prova de Matemática, sem treineiros, com cor/raça declarada,
*   tipo de escola informado e nota maior que zero (cartões totalmente em branco ficam de fora).
*   É exatamente a mesma amostra do pacote de cor/raça, o que permite comparar os dois conjuntos de resultados.
*
* FAIXAS DE RENDA (renda8), a partir de Q006. SM = salário mínimo (R$ 1.320 em 2023).
*   Até 1 SM (A-B) | 1 a 1,5 SM (C) | 1,5 a 2 SM (D) | 2 a 2,5 SM (E) | 2,5 a 3 SM (F)
*   | 3 a 4 SM (G) | 4 a 5 SM (H) | Mais de 5 SM (I a Q).
*
* REFERÊNCIA DO BLOCO 5: a faixa de maior renda (Mais de 5 SM, renda8 = 8).
*   É o grupo com o qual todos os outros são comparados: na linha dele a diferença é 0 e as razões são 1.
*
* VARIÁVEIS CRIADAS (nada é apagado do banco).
*   cor_raca, sexo, escola, renda8, pai_esc, mae_esc, esc_pais (maior escolaridade entre pai e mãe),
*   faixa (nota em faixas de 100 pontos), quartil_nota, p_top25 e p_bot25.
*   (a MÉDIA de p_top25 ou p_bot25 em um grupo é o PERCENTUAL de alunos do grupo nessa situação).
*
* =====================================================================.
* 0. CONFIGURAÇÃO.
* =====================================================================.
FILTER OFF.
USE ALL.
* Dá um nome ao conjunto de dados ativo (os blocos 3.3 e 5 criam conjuntos temporários e voltam a este).
DATASET NAME enem.
* Casas decimais das tabelas (padrão: 3). Para 4 casas: !fmtnota = F8.2 e !fmt = F9.4.
* !fmtnota = formato da nota (as tabelas automáticas mostram 2 casas a mais). !fmt = formato das tabelas montadas no script.
DEFINE !fmtnota () F8.1 !ENDDEFINE.
DEFINE !fmt () F9.3 !ENDDEFINE.
*
* =====================================================================.
* 1. PREPARAÇÃO DOS DADOS.
* =====================================================================.
* 1.1 Cor/raça. 0 (Não declarado) e 6 viram ausente.
RECODE TP_COR_RACA (1 THRU 5=COPY) (ELSE=SYSMIS) INTO cor_raca.
VARIABLE LABELS cor_raca 'Cor/raça'.
VALUE LABELS cor_raca 1 'Branca' 2 'Preta' 3 'Parda' 4 'Amarela' 5 'Indígena'.
FORMATS cor_raca (F1.0).
* 1.2 Sexo e tipo de escola.
RECODE TP_SEXO ('F'=1) ('M'=2) (ELSE=SYSMIS) INTO sexo.
VARIABLE LABELS sexo 'Sexo'.
VALUE LABELS sexo 1 'Feminino' 2 'Masculino'.
FORMATS sexo (F1.0).
RECODE TP_ESCOLA (2=2) (3=3) (ELSE=SYSMIS) INTO escola.
VARIABLE LABELS escola 'Tipo de escola do Ensino Médio'.
VALUE LABELS escola 2 'Pública' 3 'Privada'.
FORMATS escola (F1.0).
* 1.3 Renda familiar (Q006) em 8 faixas: A-B, C, D, E, F, G, H, I-Q.
RECODE Q006 ('A','B'=1) ('C'=2) ('D'=3) ('E'=4) ('F'=5) ('G'=6) ('H'=7)
  ('I','J','K','L','M','N','O','P','Q'=8) (ELSE=SYSMIS) INTO renda8.
VARIABLE LABELS renda8 'Renda familiar (8 faixas)'.
VALUE LABELS renda8 1 'Até 1 SM' 2 '1 a 1,5 SM' 3 '1,5 a 2 SM' 4 '2 a 2,5 SM' 5 '2,5 a 3 SM'
  6 '3 a 4 SM' 7 '4 a 5 SM' 8 'Mais de 5 SM'.
FORMATS renda8 (F1.0).
* 1.4 Escolaridade do pai (Q001) e da mãe (Q002). "Não sei" (H) = 0.
RECODE Q001 ('H'=0) ('A'=1) ('B'=2) ('C'=3) ('D'=4) ('E'=5) ('F'=6) ('G'=7) (ELSE=SYSMIS) INTO pai_esc.
RECODE Q002 ('H'=0) ('A'=1) ('B'=2) ('C'=3) ('D'=4) ('E'=5) ('F'=6) ('G'=7) (ELSE=SYSMIS) INTO mae_esc.
VARIABLE LABELS pai_esc 'Escolaridade do pai' mae_esc 'Escolaridade da mãe'.
VALUE LABELS pai_esc mae_esc 0 'Não sei' 1 'Nunca estudou' 2 'EF I incompleto'
  3 'EF I completo' 4 'EF completo' 5 'Médio completo' 6 'Superior completo' 7 'Pós-graduação'.
FORMATS pai_esc mae_esc (F1.0).
* 1.5 Maior escolaridade entre pai e mãe. Se um dos dois é "Não sei", vale a do outro.
COMPUTE esc_max = MAX(pai_esc, mae_esc).
RECODE esc_max (0=0) (1,2,3=1) (4=2) (5=3) (6,7=4) (ELSE=SYSMIS) INTO esc_pais.
VARIABLE LABELS esc_pais 'Maior escolaridade entre pai e mãe'.
VALUE LABELS esc_pais 0 'Não sabe (pai e mãe)' 1 'Até Fund. incompleto' 2 'Fund. completo'
  3 'Médio completo' 4 'Superior ou mais'.
FORMATS esc_pais (F1.0).
VARIABLE LEVEL cor_raca sexo escola renda8 pai_esc mae_esc esc_pais (NOMINAL).
* 1.6 Formato de exibição da nota (só altera a exibição, não os valores).
* Nas tabelas automáticas (bloco 3) o SPSS 22 acrescenta 2 casas decimais a este formato: F8.1 resulta em 3 casas.
FORMATS NU_NOTA_MT (!fmtnota).
* 1.7 Nota em faixas de 100 pontos.
DO IF (NU_NOTA_MT < 400).
  COMPUTE faixa = 1.
ELSE IF (NU_NOTA_MT < 500).
  COMPUTE faixa = 2.
ELSE IF (NU_NOTA_MT < 600).
  COMPUTE faixa = 3.
ELSE IF (NU_NOTA_MT < 700).
  COMPUTE faixa = 4.
ELSE IF (NU_NOTA_MT >= 700).
  COMPUTE faixa = 5.
END IF.
VARIABLE LABELS faixa 'Faixa de nota em Matemática'.
VALUE LABELS faixa 1 'Abaixo de 400' 2 '400 a 499' 3 '500 a 599' 4 '600 a 699' 5 '700 ou mais'.
FORMATS faixa (F1.0).
VARIABLE LEVEL faixa (ORDINAL).
EXECUTE.
*
* =====================================================================.
* BLOCO 1. QUEM ENTRA NA ANÁLISE (fluxo de seleção).
* =====================================================================.
COMPUTE selecao = 9.
IF (TP_PRESENCA_MT = 1 AND IN_TREINEIRO = 0 AND TP_ST_CONCLUSAO = 2) selecao = 1.
IF (selecao = 1 AND MISSING(cor_raca)) selecao = 2.
IF (selecao = 1 AND MISSING(escola)) selecao = 3.
IF (selecao = 1 AND NMISS(NU_NOTA_MT, sexo, renda8, pai_esc, mae_esc) > 0) selecao = 5.
IF (selecao = 1 AND NU_NOTA_MT = 0) selecao = 4.
VARIABLE LABELS selecao 'Situação no recorte da análise'.
VALUE LABELS selecao 1 'Incluído na análise' 2 'Cor/raça não declarada' 3 'Tipo de escola não informado'
  4 'Nota zero (cartão em branco)' 5 'Outra variável ausente' 9 'Fora do recorte (ausente, treineiro ou não concluinte)'.
FORMATS selecao (F1.0).
COMPUTE amostra_A = (selecao = 1).
VARIABLE LABELS amostra_A 'Amostra da análise descritiva'.
VALUE LABELS amostra_A 0 'Fora' 1 'Dentro'.
FORMATS amostra_A (F1.0).
EXECUTE.
FREQUENCIES VARIABLES=selecao.
* A partir daqui, tudo roda apenas na amostra da análise.
FILTER BY amostra_A.
* Quartis calculados dentro da amostra da análise.
RANK VARIABLES=NU_NOTA_MT (A)
  /NTILES(4) INTO quartil_nota
  /PRINT=NO.
COMPUTE p_top25 = 100 * (quartil_nota = 4).
COMPUTE p_bot25 = 100 * (quartil_nota = 1).
VARIABLE LABELS quartil_nota 'Quartil da nota'
  p_top25 'Entre os 25% maiores notas (média = %)' p_bot25 'Entre os 25% menores notas (média = %)'.
VALUE LABELS quartil_nota 1 '1º quartil (25% menores)' 2 '2º quartil' 3 '3º quartil' 4 '4º quartil (25% maiores)'.
FORMATS quartil_nota (F1.0).
EXECUTE.
* Oculta as tabelas "Resumo de processamento de casos" (o N de cada análise já aparece nas tabelas).
OMS
  /SELECT TABLES
  /IF SUBTYPES=['Case Processing Summary']
  /DESTINATION VIEWER=NO
  /TAG='ocultar_resumo'.
*
* =====================================================================.
* BLOCO 2. PERFIL DE CADA FAIXA DE RENDA.
* Percentuais nas colunas: cada coluna soma 100%.
* =====================================================================.
CROSSTABS
  /TABLES=escola cor_raca esc_pais sexo BY renda8
  /FORMAT=AVALUE TABLES
  /CELLS=COUNT COLUMN
  /COUNT ROUND CELL.
*
* =====================================================================.
* BLOCO 3. NOTA DE MATEMÁTICA POR FAIXA DE RENDA.
* =====================================================================.
* 3.1 Número de alunos, média e mediana por faixa de renda.
MEANS TABLES=NU_NOTA_MT BY renda8
  /CELLS=COUNT MEAN MEDIAN.
* 3.2 Cortes da nota na amostra inteira (percentis 10, 25, 50, 75 e 90).
FREQUENCIES VARIABLES=NU_NOTA_MT
  /FORMAT=NOTABLE
  /PERCENTILES=10 25 50 75 90
  /STATISTICS=MEAN MEDIAN.
* 3.3 Percentis por faixa de renda (10, 25, 50, 75 e 90), em uma tabela com uma linha por grupo.
* Método: média ponderada, definição 1 (o mesmo que o EXAMINE usa por padrão): posição (n+1)p, com interpolação.
* Cria um conjunto de dados temporário (pct) só com os alunos da análise, calcula os percentis nele e volta ao banco original.
DATASET COPY pct.
DATASET ACTIVATE pct.
FILTER OFF.
USE ALL.
SELECT IF (amostra_A = 1).
EXECUTE.
MATCH FILES /FILE=* /KEEP=renda8 NU_NOTA_MT.
SORT CASES BY renda8 (A) NU_NOTA_MT (A).
* Tamanho do grupo (ng) e posição (pos) de cada nota dentro do seu grupo, já em ordem crescente.
COMPUTE seq = $CASENUM.
AGGREGATE
  /OUTFILE=* MODE=ADDVARIABLES
  /BREAK=renda8
  /ng=N
  /seq0=MIN(seq).
COMPUTE pos = seq - seq0 + 1.
* Para cada percentil p: tt = (ng+1)*p/100, kk = parte inteira de tt e gg = parte fracionária.
* Percentil = (1-gg) * nota na posição kk + gg * nota na posição kk+1 (se tt < 1 ou tt >= ng, vale a menor ou a maior nota).
* Cada caso guarda só a sua parte da conta (vp). A soma dos casos do grupo (AGGREGATE, a seguir) é o percentil.
DO REPEAT pc = 10 25 50 75 90 / vp = vp10 vp25 vp50 vp75 vp90.
  COMPUTE tt = (ng + 1) * pc / 100.
  COMPUTE kk = TRUNC(tt).
  COMPUTE gg = tt - kk.
  IF (tt < 1) kk = 1.
  IF (tt < 1) gg = 0.
  IF (tt >= ng) kk = ng.
  IF (tt >= ng) gg = 0.
  COMPUTE vp = 0.
  IF (pos = kk) vp = (1 - gg) * NU_NOTA_MT.
  IF (pos = kk + 1) vp = gg * NU_NOTA_MT.
END REPEAT.
EXECUTE.
AGGREGATE
  /OUTFILE=*
  /BREAK=renda8
  /n=MAX(ng)
  /p10=SUM(vp10) /p25=SUM(vp25) /p50=SUM(vp50) /p75=SUM(vp75) /p90=SUM(vp90).
VARIABLE LABELS n 'Alunos' p10 'P10' p25 'P25' p50 'P50 (mediana)' p75 'P75' p90 'P90'.
FORMATS n (DOT9.0).
FORMATS p10 p25 p50 p75 p90 (!fmt).
EXECUTE.
SUMMARIZE
  /TABLES=renda8 n p10 p25 p50 p75 p90
  /FORMAT=LIST NOCASENUM NOTOTAL
  /TITLE='Percentis da nota de Matemática por faixa de renda'
  /FOOTNOTE='Percentis pelo método da média ponderada (definição 1, padrão do SPSS). P50 = mediana.'
  /MISSING=VARIABLE
  /CELLS=NONE.
DATASET ACTIVATE enem.
DATASET CLOSE pct.
* 3.4 Boxplot da nota por faixa de renda.
EXAMINE VARIABLES=NU_NOTA_MT BY renda8
  /PLOT=BOXPLOT
  /COMPARE=GROUPS
  /STATISTICS=NONE
  /MISSING=LISTWISE
  /NOTOTAL.
*
* =====================================================================.
* BLOCO 4. COMO AS NOTAS SE DISTRIBUEM ENTRE AS FAIXAS DE RENDA.
* Percentuais nas colunas: cada coluna soma 100%. A coluna "Total" é a referência (todos os alunos).
* =====================================================================.
CROSSTABS
  /TABLES=faixa quartil_nota BY renda8
  /FORMAT=AVALUE TABLES
  /CELLS=COUNT COLUMN
  /COUNT ROUND CELL.
*
* =====================================================================.
* BLOCO 5. QUADRO-SÍNTESE: RETRATO GERAL DE CADA FAIXA DE RENDA.
* Uma linha por faixa de renda, com todos os alunos da amostra (sem separar por cor/raça, escola ou escolaridade dos pais).
* Os números vêm dos mesmos dados dos blocos 3 (nota média) e 4 (quartis). O quadro acrescenta duas contas.
* A referência é a faixa de maior renda (Mais de 5 SM, renda8 = 8).
*   Pontos abaixo da referência = média da referência menos a média do grupo.
*   Razões entre percentuais: entre os 25% maiores notas, % da referência dividido pelo % do grupo;
*   entre os 25% menores notas, % do grupo dividido pelo % da referência.
* O bloco cria um conjunto de dados temporário (agg) de 8 linhas, faz as contas nele e volta ao banco original.
* =====================================================================.
DATASET DECLARE agg.
AGGREGATE
  /OUTFILE=agg
  /BREAK=renda8
  /n=N
  /media=MEAN(NU_NOTA_MT)
  /pct_top=MEAN(p_top25)
  /pct_bot=MEAN(p_bot25).
DATASET ACTIVATE agg.
* Valores da referência (renda8 = 8), copiados para todas as linhas.
IF (renda8 = 8) r_media = media.
IF (renda8 = 8) r_top = pct_top.
IF (renda8 = 8) r_bot = pct_bot.
AGGREGATE
  /OUTFILE=* MODE=ADDVARIABLES
  /ref_media=MAX(r_media)
  /ref_top=MAX(r_top)
  /ref_bot=MAX(r_bot).
COMPUTE dif_pontos = ref_media - media.
COMPUTE razao_top = ref_top / pct_top.
COMPUTE razao_bot = pct_bot / ref_bot.
VARIABLE LABELS renda8 'Faixa de renda' n 'Alunos' media 'Nota média' dif_pontos 'Pontos abaixo da referência'
  pct_top '% entre os 25% maiores' razao_top 'Referência ÷ grupo'
  pct_bot '% entre os 25% menores' razao_bot 'Grupo ÷ referência'.
VALUE LABELS renda8 1 'Até 1 SM' 2 '1 a 1,5 SM' 3 '1,5 a 2 SM' 4 '2 a 2,5 SM' 5 '2,5 a 3 SM'
  6 '3 a 4 SM' 7 '4 a 5 SM' 8 'Mais de 5 SM (referência)'.
FORMATS n (DOT9.0).
FORMATS media dif_pontos (!fmt).
FORMATS pct_top pct_bot razao_top razao_bot (!fmt).
EXECUTE.
SUMMARIZE
  /TABLES=renda8 n media dif_pontos pct_top razao_top pct_bot razao_bot
  /FORMAT=LIST NOCASENUM NOTOTAL
  /TITLE='Quadro-síntese: retrato geral de cada faixa de renda'
  /FOOTNOTE='Referência: Mais de 5 SM. Pontos abaixo: média da referência menos a do grupo. Referência ÷ grupo: % da referência entre os 25% maiores / % do grupo. Grupo ÷ referência: % do grupo entre os 25% menores / % da referência.'
  /MISSING=VARIABLE
  /CELLS=NONE.
DATASET ACTIVATE enem.
DATASET CLOSE agg.
