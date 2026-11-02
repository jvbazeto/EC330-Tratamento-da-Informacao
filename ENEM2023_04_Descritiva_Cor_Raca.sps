* Encoding: UTF-8.
* =====================================================================.
* ENEM 2023 - NOTA DE MATEMÁTICA E COR/RAÇA: PACOTE ESSENCIAL.
* Análise descritiva simples: médias, medianas, percentis, frequências e proporções.
* Compatível com SPSS 22.
* =====================================================================.
*
* COMO USAR.
* 1) Abra o banco .sav completo (File > Open > Data) e deixe-o como conjunto ativo.
* 2) Abra este arquivo (File > Open > Syntax) e rode tudo (Run > All).
*
* O QUE O PACOTE PRODUZ (25 tabelas e 4 gráficos).
*   Bloco 1  Quem entra na análise: 1 tabela (fluxo de seleção).
*   Bloco 2  Perfil de cada cor/raça: 4 tabelas (escola, renda, escolaridade dos pais, sexo).
*   Bloco 3  Nota por cor/raça: 3 tabelas (média e mediana; cortes gerais; percentis por cor/raça) + boxplot.
*   Bloco 4  Distribuição das notas entre os grupos: 2 tabelas (faixas de nota e quartis).
*   Bloco 5  Quadro-síntese: 1 tabela, com uma linha por cor/raça.
*   Bloco 6  Nota por cor/raça dentro de cada fator: 8 tabelas (média e mediana por renda, escola, escolaridade dos pais, sexo) + 3 gráficos.
*   Bloco 7  Proporção entre as maiores e as menores notas, por renda: 2 tabelas.
*   Bloco 8  Renda fixa, escolaridade dos pais variando, por cor/raça: 2 tabelas (médias e diferenças; número de alunos).
*   Bloco 9  Renda fixa, tipo de escola variando, por cor/raça: 2 tabelas (médias e diferenças; número de alunos).
*
* REGRA DO NÚMERO MÍNIMO DE ALUNOS (blocos 6, 7, 8 e 9).
*   Médias, medianas e percentuais só aparecem quando a cor/raça tem 100 ou mais alunos na linha; nas demais células aparece "n baixo".
*   Para mudar o limite, altere o número no DEFINE !nmin (seção 0) e o texto "menos de 100 alunos" nos rodapés (SUMMARIZE).
*
* AMOSTRA ANALISADA (variável amostra_A = 1).
*   Concluintes de 2023 presentes na prova de Matemática, sem treineiros, com cor/raça declarada,
*   tipo de escola informado e nota maior que zero.
*
* FAIXAS DE RENDA (renda8), a partir de Q006. SM = salário mínimo (R$ 1.320 em 2023).
*   Até 1 SM (A-B) | 1 a 1,5 SM (C) | 1,5 a 2 SM (D) | 2 a 2,5 SM (E) | 2,5 a 3 SM (F)
*   | 3 a 4 SM (G) | 4 a 5 SM (H) | Mais de 5 SM (I a Q).
*
* VARIÁVEIS CRIADAS.
*   cor_raca, sexo, escola, renda8, pai_esc, mae_esc, esc_pais (maior escolaridade entre pai e mãe),
*   faixa (nota em faixas de 100 pontos), quartil_nota, p_top25 e p_bot25.
*   (a MÉDIA de p_top25 ou p_bot25 em um grupo é o PERCENTUAL de alunos do grupo nessa situação).
*
* =====================================================================.
* 0. CONFIGURAÇÃO.
* =====================================================================.
FILTER OFF.
USE ALL.
* Nome do conjunto de dados ativo (os blocos 3.3, 5, 6, 7, 8 e 9 criam conjuntos temporários e voltam a este).
DATASET NAME enem.
* Número mínimo de alunos por célula nas tabelas dos blocos 6, 7, 8 e 9.
DEFINE !nmin () 100 !ENDDEFINE.
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
* 1.6 Exibição da nota com 3 casas decimais: nas tabelas automáticas o SPSS soma 2 casas ao formato F8.1; nas tabelas com SUMMARIZE o formato é F8.3.
FORMATS NU_NOTA_MT (F8.1).
* 1.7 Nota em faixas de 100 pontos.
DO IF (NU_NOTA_MT < 400).
  COMPUTE faixa = 1.
ELSE IF (NU_NOTA_MT < 500).
  COMPUTE faixa = 2.
ELSE IF (NU_NOTA_MT < 600).
  COMPUTE faixa = 3.
ELSE IF (NU_NOTA_MT < 700).
  COMPUTE faixa = 4.
ELSE IF (NU_NOTA_MT < 800).
  COMPUTE faixa = 5.
ELSE IF (NU_NOTA_MT < 900).
  COMPUTE faixa = 6.
ELSE IF (NU_NOTA_MT >= 900).
  COMPUTE faixa = 7.
END IF.
VARIABLE LABELS faixa 'Faixa de nota em Matemática'.
VALUE LABELS faixa 1 'Abaixo de 400' 2 '400 a 499,99' 3 '500 a 599,99' 4 '600 a 699,99' 5 '700 a 799,99'
  6 '800 a 899,99' 7 '900 ou mais'.
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
* Oculta as tabelas "Resumo de processamento de casos".
OMS
  /SELECT TABLES
  /IF SUBTYPES=['Case Processing Summary']
  /DESTINATION VIEWER=NO
  /TAG='ocultar_resumo'.
*
* =====================================================================.
* BLOCO 2. PERFIL DE CADA COR/RAÇA.
* Percentuais nas colunas: cada coluna soma 100%.
* =====================================================================.
CROSSTABS
  /TABLES=escola renda8 esc_pais sexo BY cor_raca
  /FORMAT=AVALUE TABLES
  /CELLS=COUNT COLUMN
  /COUNT ROUND CELL.
*
* =====================================================================.
* BLOCO 3. NOTA DE MATEMÁTICA POR COR/RAÇA.
* =====================================================================.
* 3.1 Número de alunos, média e mediana por cor/raça.
MEANS TABLES=NU_NOTA_MT BY cor_raca
  /CELLS=COUNT MEAN MEDIAN.
* 3.2 Cortes da nota na amostra inteira (percentis 10, 25, 50, 75 e 90).
FREQUENCIES VARIABLES=NU_NOTA_MT
  /FORMAT=NOTABLE
  /PERCENTILES=10 25 50 75 90
  /STATISTICS=MEAN MEDIAN.
* 3.3 Percentis por cor/raça (10, 25, 50, 75 e 90), pela média ponderada (definição 1).
* Conjunto auxiliar perc: número de alunos em cada nota (f) por cor/raça, com o total (n) e o acumulado (cum).
DATASET DECLARE perc.
AGGREGATE
  /OUTFILE=perc
  /BREAK=cor_raca NU_NOTA_MT
  /f=N.
DATASET ACTIVATE perc.
SORT CASES BY cor_raca NU_NOTA_MT.
AGGREGATE
  /OUTFILE=* MODE=ADDVARIABLES
  /BREAK=cor_raca
  /n=SUM(f).
DO IF ($CASENUM = 1 OR cor_raca <> LAG(cor_raca)).
  COMPUTE cum = f.
ELSE.
  COMPUTE cum = cum + f.
END IF.
LEAVE cum.
* Percentil P = média entre a nota na posição (n + 1) x P / 100 (ilo) e a seguinte (ihi), ponderada pela parte decimal (peso).
* Cada linha contribui (c) com sua nota se ocupar uma dessas posições; a soma por cor/raça é o percentil.
DO REPEAT p = 10 25 50 75 90 / c = c10 c25 c50 c75 c90.
  COMPUTE pos = (n + 1) * p / 100.
  COMPUTE ilo = MAX(TRUNC(pos), 1).
  COMPUTE ihi = MIN(TRUNC(pos) + 1, n).
  COMPUTE peso = pos - TRUNC(pos).
  COMPUTE c = 0.
  IF (cum - f < ilo AND ilo <= cum) c = c + (1 - peso) * NU_NOTA_MT.
  IF (cum - f < ihi AND ihi <= cum) c = c + peso * NU_NOTA_MT.
END REPEAT.
EXECUTE.
AGGREGATE
  /OUTFILE=*
  /BREAK=cor_raca
  /pc10=SUM(c10) /pc25=SUM(c25) /pc50=SUM(c50) /pc75=SUM(c75) /pc90=SUM(c90).
VARIABLE LABELS cor_raca 'Cor/raça' pc10 'Percentil 10' pc25 'Percentil 25' pc50 'Percentil 50 (mediana)'
  pc75 'Percentil 75' pc90 'Percentil 90'.
VALUE LABELS cor_raca 1 'Branca' 2 'Preta' 3 'Parda' 4 'Amarela' 5 'Indígena'.
FORMATS pc10 pc25 pc50 pc75 pc90 (F8.3).
EXECUTE.
SUMMARIZE
  /TABLES=cor_raca pc10 pc25 pc50 pc75 pc90
  /FORMAT=LIST NOCASENUM NOTOTAL
  /TITLE='Percentis da nota de Matemática por cor/raça'
  /FOOTNOTE='Percentis pelo método da média ponderada (definição 1). O percentil 50 é a mediana.'
  /MISSING=VARIABLE
  /CELLS=NONE.
DATASET ACTIVATE enem.
DATASET CLOSE perc.
* 3.4 Boxplot da nota por cor/raça.
EXAMINE VARIABLES=NU_NOTA_MT BY cor_raca
  /PLOT=BOXPLOT
  /COMPARE=GROUPS
  /STATISTICS=NONE
  /MISSING=LISTWISE
  /NOTOTAL.
*
* =====================================================================.
* BLOCO 4. COMO AS NOTAS SE DISTRIBUEM ENTRE OS GRUPOS.
* Percentuais nas colunas: cada coluna soma 100%. A coluna "Total" é a referência (todos os alunos).
* =====================================================================.
CROSSTABS
  /TABLES=faixa quartil_nota BY cor_raca
  /FORMAT=AVALUE TABLES
  /CELLS=COUNT COLUMN
  /COUNT ROUND CELL.
*
* =====================================================================.
* BLOCO 5. QUADRO-SÍNTESE: RETRATO GERAL DE CADA COR/RAÇA.
* Uma linha por cor/raça, com todos os alunos da amostra.
* Colunas calculadas:
*   Pontos abaixo dos brancos = média dos brancos menos a média do grupo.
*   Razões entre percentuais: entre os 25% maiores notas, % de brancos dividido pelo % do grupo;
*   entre os 25% menores notas, % do grupo dividido pelo % de brancos.
* =====================================================================.
DATASET DECLARE agg.
AGGREGATE
  /OUTFILE=agg
  /BREAK=cor_raca
  /n=N
  /media=MEAN(NU_NOTA_MT)
  /pct_top=MEAN(p_top25)
  /pct_bot=MEAN(p_bot25).
DATASET ACTIVATE agg.
* Valores dos brancos (cor/raça = 1), copiados para todas as linhas como referência.
IF (cor_raca = 1) r_media = media.
IF (cor_raca = 1) r_top = pct_top.
IF (cor_raca = 1) r_bot = pct_bot.
AGGREGATE
  /OUTFILE=* MODE=ADDVARIABLES
  /ref_media=MAX(r_media)
  /ref_top=MAX(r_top)
  /ref_bot=MAX(r_bot).
COMPUTE dif_pontos = ref_media - media.
COMPUTE razao_top = ref_top / pct_top.
COMPUTE razao_bot = pct_bot / ref_bot.
VARIABLE LABELS cor_raca 'Grupo' n 'Alunos' media 'Nota média' dif_pontos 'Pontos abaixo dos brancos'
  pct_top '% entre os 25% maiores' razao_top 'Brancos ÷ grupo'
  pct_bot '% entre os 25% menores' razao_bot 'Grupo ÷ brancos'.
VALUE LABELS cor_raca 1 'Brancos' 2 'Pretos' 3 'Pardos' 4 'Amarelos' 5 'Indígenas'.
FORMATS n (DOT9.0).
FORMATS media dif_pontos pct_top pct_bot razao_top razao_bot (F8.3).
EXECUTE.
SUMMARIZE
  /TABLES=cor_raca n media dif_pontos pct_top razao_top pct_bot razao_bot
  /FORMAT=LIST NOCASENUM NOTOTAL
  /TITLE='Quadro-síntese: retrato geral de cada cor/raça'
  /FOOTNOTE='Pontos abaixo dos brancos: média dos brancos menos a do grupo. Brancos ÷ grupo: % de brancos entre os 25% maiores / % do grupo. Grupo ÷ brancos: % do grupo entre os 25% menores / % de brancos.'
  /MISSING=VARIABLE
  /CELLS=NONE.
DATASET ACTIVATE enem.
DATASET CLOSE agg.
*
* =====================================================================.
* BLOCO 6. NOTA POR COR/RAÇA DENTRO DE CADA FATOR.
* Para cada fator (renda, tipo de escola, escolaridade dos pais e sexo), 2 tabelas: nota média e nota mediana.
* Cada linha é uma categoria do fator; as colunas são as cores/raças e "Todos" (todos os alunos da categoria).
* =====================================================================.
* Para cada cor/raça (1 = Branca ... 5 = Indígena), cria um indicador (ind_k) e a nota só desse grupo (nota_k).
DO REPEAT ind = ind_1 ind_2 ind_3 ind_4 ind_5 / nota = nota_1 nota_2 nota_3 nota_4 nota_5 / k = 1 2 3 4 5.
  COMPUTE ind = (cor_raca = k).
  IF (cor_raca = k) nota = NU_NOTA_MT.
END REPEAT.
EXECUTE.
* 6.1 Renda familiar.
DATASET DECLARE agg.
AGGREGATE
  /OUTFILE=agg
  /BREAK=renda8
  /n_1=SUM(ind_1) /n_2=SUM(ind_2) /n_3=SUM(ind_3) /n_4=SUM(ind_4) /n_5=SUM(ind_5)
  /media_1=MEAN(nota_1) /media_2=MEAN(nota_2) /media_3=MEAN(nota_3) /media_4=MEAN(nota_4) /media_5=MEAN(nota_5)
  /media_t=MEAN(NU_NOTA_MT)
  /mediana_1=MEDIAN(nota_1) /mediana_2=MEDIAN(nota_2) /mediana_3=MEDIAN(nota_3) /mediana_4=MEDIAN(nota_4)
  /mediana_5=MEDIAN(nota_5) /mediana_t=MEDIAN(NU_NOTA_MT).
DATASET ACTIVATE agg.
* Médias e medianas de cor/raça com menos alunos que o limite (nmin) ficam em branco ("n baixo").
DO REPEAT m = media_1 media_2 media_3 media_4 media_5 / d = mediana_1 mediana_2 mediana_3 mediana_4 mediana_5
  / q = n_1 n_2 n_3 n_4 n_5.
  IF (q < !nmin) m = $SYSMIS.
  IF (q < !nmin) d = $SYSMIS.
END REPEAT.
VARIABLE LABELS media_1 'Branca' media_2 'Preta' media_3 'Parda' media_4 'Amarela' media_5 'Indígena' media_t 'Todos'
  mediana_1 'Branca' mediana_2 'Preta' mediana_3 'Parda' mediana_4 'Amarela' mediana_5 'Indígena' mediana_t 'Todos'.
FORMATS media_1 media_2 media_3 media_4 media_5 media_t mediana_1 mediana_2 mediana_3 mediana_4 mediana_5 mediana_t (F8.3).
EXECUTE.
SUMMARIZE
  /TABLES=renda8 media_1 media_2 media_3 media_4 media_5 media_t
  /FORMAT=LIST NOCASENUM NOTOTAL MISSING='n baixo'
  /TITLE='Nota média por faixa de renda e cor/raça'
  /FOOTNOTE='n baixo: menos de 100 alunos do grupo na linha (média não exibida). Todos: todos os alunos da linha.'
  /MISSING=VARIABLE
  /CELLS=NONE.
SUMMARIZE
  /TABLES=renda8 mediana_1 mediana_2 mediana_3 mediana_4 mediana_5 mediana_t
  /FORMAT=LIST NOCASENUM NOTOTAL MISSING='n baixo'
  /TITLE='Nota mediana por faixa de renda e cor/raça'
  /FOOTNOTE='n baixo: menos de 100 alunos do grupo na linha (mediana não exibida). Todos: todos os alunos da linha.'
  /MISSING=VARIABLE
  /CELLS=NONE.
DATASET ACTIVATE enem.
DATASET CLOSE agg.
GRAPH
  /LINE(MULTIPLE)=MEAN(NU_NOTA_MT) BY renda8 BY cor_raca
  /TITLE='Nota média em Matemática por faixa de renda e cor/raça'.
* 6.2 Tipo de escola.
DATASET DECLARE agg.
AGGREGATE
  /OUTFILE=agg
  /BREAK=escola
  /n_1=SUM(ind_1) /n_2=SUM(ind_2) /n_3=SUM(ind_3) /n_4=SUM(ind_4) /n_5=SUM(ind_5)
  /media_1=MEAN(nota_1) /media_2=MEAN(nota_2) /media_3=MEAN(nota_3) /media_4=MEAN(nota_4) /media_5=MEAN(nota_5)
  /media_t=MEAN(NU_NOTA_MT)
  /mediana_1=MEDIAN(nota_1) /mediana_2=MEDIAN(nota_2) /mediana_3=MEDIAN(nota_3) /mediana_4=MEDIAN(nota_4)
  /mediana_5=MEDIAN(nota_5) /mediana_t=MEDIAN(NU_NOTA_MT).
DATASET ACTIVATE agg.
DO REPEAT m = media_1 media_2 media_3 media_4 media_5 / d = mediana_1 mediana_2 mediana_3 mediana_4 mediana_5
  / q = n_1 n_2 n_3 n_4 n_5.
  IF (q < !nmin) m = $SYSMIS.
  IF (q < !nmin) d = $SYSMIS.
END REPEAT.
VARIABLE LABELS media_1 'Branca' media_2 'Preta' media_3 'Parda' media_4 'Amarela' media_5 'Indígena' media_t 'Todos'
  mediana_1 'Branca' mediana_2 'Preta' mediana_3 'Parda' mediana_4 'Amarela' mediana_5 'Indígena' mediana_t 'Todos'.
FORMATS media_1 media_2 media_3 media_4 media_5 media_t mediana_1 mediana_2 mediana_3 mediana_4 mediana_5 mediana_t (F8.3).
EXECUTE.
SUMMARIZE
  /TABLES=escola media_1 media_2 media_3 media_4 media_5 media_t
  /FORMAT=LIST NOCASENUM NOTOTAL MISSING='n baixo'
  /TITLE='Nota média por tipo de escola e cor/raça'
  /FOOTNOTE='n baixo: menos de 100 alunos do grupo na linha (média não exibida). Todos: todos os alunos da linha.'
  /MISSING=VARIABLE
  /CELLS=NONE.
SUMMARIZE
  /TABLES=escola mediana_1 mediana_2 mediana_3 mediana_4 mediana_5 mediana_t
  /FORMAT=LIST NOCASENUM NOTOTAL MISSING='n baixo'
  /TITLE='Nota mediana por tipo de escola e cor/raça'
  /FOOTNOTE='n baixo: menos de 100 alunos do grupo na linha (mediana não exibida). Todos: todos os alunos da linha.'
  /MISSING=VARIABLE
  /CELLS=NONE.
DATASET ACTIVATE enem.
DATASET CLOSE agg.
GRAPH
  /BAR(GROUPED)=MEAN(NU_NOTA_MT) BY escola BY cor_raca
  /TITLE='Nota média em Matemática por tipo de escola e cor/raça'.
* 6.3 Escolaridade dos pais.
DATASET DECLARE agg.
AGGREGATE
  /OUTFILE=agg
  /BREAK=esc_pais
  /n_1=SUM(ind_1) /n_2=SUM(ind_2) /n_3=SUM(ind_3) /n_4=SUM(ind_4) /n_5=SUM(ind_5)
  /media_1=MEAN(nota_1) /media_2=MEAN(nota_2) /media_3=MEAN(nota_3) /media_4=MEAN(nota_4) /media_5=MEAN(nota_5)
  /media_t=MEAN(NU_NOTA_MT)
  /mediana_1=MEDIAN(nota_1) /mediana_2=MEDIAN(nota_2) /mediana_3=MEDIAN(nota_3) /mediana_4=MEDIAN(nota_4)
  /mediana_5=MEDIAN(nota_5) /mediana_t=MEDIAN(NU_NOTA_MT).
DATASET ACTIVATE agg.
DO REPEAT m = media_1 media_2 media_3 media_4 media_5 / d = mediana_1 mediana_2 mediana_3 mediana_4 mediana_5
  / q = n_1 n_2 n_3 n_4 n_5.
  IF (q < !nmin) m = $SYSMIS.
  IF (q < !nmin) d = $SYSMIS.
END REPEAT.
VARIABLE LABELS media_1 'Branca' media_2 'Preta' media_3 'Parda' media_4 'Amarela' media_5 'Indígena' media_t 'Todos'
  mediana_1 'Branca' mediana_2 'Preta' mediana_3 'Parda' mediana_4 'Amarela' mediana_5 'Indígena' mediana_t 'Todos'.
FORMATS media_1 media_2 media_3 media_4 media_5 media_t mediana_1 mediana_2 mediana_3 mediana_4 mediana_5 mediana_t (F8.3).
EXECUTE.
SUMMARIZE
  /TABLES=esc_pais media_1 media_2 media_3 media_4 media_5 media_t
  /FORMAT=LIST NOCASENUM NOTOTAL MISSING='n baixo'
  /TITLE='Nota média por escolaridade dos pais e cor/raça'
  /FOOTNOTE='n baixo: menos de 100 alunos do grupo na linha (média não exibida). Todos: todos os alunos da linha.'
  /MISSING=VARIABLE
  /CELLS=NONE.
SUMMARIZE
  /TABLES=esc_pais mediana_1 mediana_2 mediana_3 mediana_4 mediana_5 mediana_t
  /FORMAT=LIST NOCASENUM NOTOTAL MISSING='n baixo'
  /TITLE='Nota mediana por escolaridade dos pais e cor/raça'
  /FOOTNOTE='n baixo: menos de 100 alunos do grupo na linha (mediana não exibida). Todos: todos os alunos da linha.'
  /MISSING=VARIABLE
  /CELLS=NONE.
DATASET ACTIVATE enem.
DATASET CLOSE agg.
TEMPORARY.
SELECT IF (esc_pais > 0).
GRAPH
  /LINE(MULTIPLE)=MEAN(NU_NOTA_MT) BY esc_pais BY cor_raca
  /TITLE='Nota média em Matemática por escolaridade dos pais e cor/raça (sem "Não sabe")'.
* 6.4 Sexo.
DATASET DECLARE agg.
AGGREGATE
  /OUTFILE=agg
  /BREAK=sexo
  /n_1=SUM(ind_1) /n_2=SUM(ind_2) /n_3=SUM(ind_3) /n_4=SUM(ind_4) /n_5=SUM(ind_5)
  /media_1=MEAN(nota_1) /media_2=MEAN(nota_2) /media_3=MEAN(nota_3) /media_4=MEAN(nota_4) /media_5=MEAN(nota_5)
  /media_t=MEAN(NU_NOTA_MT)
  /mediana_1=MEDIAN(nota_1) /mediana_2=MEDIAN(nota_2) /mediana_3=MEDIAN(nota_3) /mediana_4=MEDIAN(nota_4)
  /mediana_5=MEDIAN(nota_5) /mediana_t=MEDIAN(NU_NOTA_MT).
DATASET ACTIVATE agg.
DO REPEAT m = media_1 media_2 media_3 media_4 media_5 / d = mediana_1 mediana_2 mediana_3 mediana_4 mediana_5
  / q = n_1 n_2 n_3 n_4 n_5.
  IF (q < !nmin) m = $SYSMIS.
  IF (q < !nmin) d = $SYSMIS.
END REPEAT.
VARIABLE LABELS media_1 'Branca' media_2 'Preta' media_3 'Parda' media_4 'Amarela' media_5 'Indígena' media_t 'Todos'
  mediana_1 'Branca' mediana_2 'Preta' mediana_3 'Parda' mediana_4 'Amarela' mediana_5 'Indígena' mediana_t 'Todos'.
FORMATS media_1 media_2 media_3 media_4 media_5 media_t mediana_1 mediana_2 mediana_3 mediana_4 mediana_5 mediana_t (F8.3).
EXECUTE.
SUMMARIZE
  /TABLES=sexo media_1 media_2 media_3 media_4 media_5 media_t
  /FORMAT=LIST NOCASENUM NOTOTAL MISSING='n baixo'
  /TITLE='Nota média por sexo e cor/raça'
  /FOOTNOTE='n baixo: menos de 100 alunos do grupo na linha (média não exibida). Todos: todos os alunos da linha.'
  /MISSING=VARIABLE
  /CELLS=NONE.
SUMMARIZE
  /TABLES=sexo mediana_1 mediana_2 mediana_3 mediana_4 mediana_5 mediana_t
  /FORMAT=LIST NOCASENUM NOTOTAL MISSING='n baixo'
  /TITLE='Nota mediana por sexo e cor/raça'
  /FOOTNOTE='n baixo: menos de 100 alunos do grupo na linha (mediana não exibida). Todos: todos os alunos da linha.'
  /MISSING=VARIABLE
  /CELLS=NONE.
DATASET ACTIVATE enem.
DATASET CLOSE agg.
* Remove as variáveis auxiliares do banco.
DELETE VARIABLES ind_1 ind_2 ind_3 ind_4 ind_5 nota_1 nota_2 nota_3 nota_4 nota_5.
*
* =====================================================================.
* BLOCO 7. PROPORÇÃO ENTRE AS MAIORES E AS MENORES NOTAS, POR FAIXA DE RENDA.
* Cada célula é o PERCENTUAL de alunos da cor/raça, naquela faixa de renda, entre os 25% maiores notas (1ª tabela)
* ou entre os 25% menores notas (2ª tabela) de toda a amostra. A coluna "Todos" é a referência da faixa.
* =====================================================================.
* Para cada cor/raça (1 = Branca ... 5 = Indígena), cria um indicador e as marcas de maior/menor nota só desse grupo.
DO REPEAT ind = ind_1 ind_2 ind_3 ind_4 ind_5 / top = top_1 top_2 top_3 top_4 top_5
  / bot = bot_1 bot_2 bot_3 bot_4 bot_5 / k = 1 2 3 4 5.
  COMPUTE ind = (cor_raca = k).
  IF (cor_raca = k) top = p_top25.
  IF (cor_raca = k) bot = p_bot25.
END REPEAT.
EXECUTE.
DATASET DECLARE agg.
AGGREGATE
  /OUTFILE=agg
  /BREAK=renda8
  /n_1=SUM(ind_1) /n_2=SUM(ind_2) /n_3=SUM(ind_3) /n_4=SUM(ind_4) /n_5=SUM(ind_5)
  /pt_1=MEAN(top_1) /pt_2=MEAN(top_2) /pt_3=MEAN(top_3) /pt_4=MEAN(top_4) /pt_5=MEAN(top_5) /pt_t=MEAN(p_top25)
  /pb_1=MEAN(bot_1) /pb_2=MEAN(bot_2) /pb_3=MEAN(bot_3) /pb_4=MEAN(bot_4) /pb_5=MEAN(bot_5) /pb_t=MEAN(p_bot25).
* Remove as variáveis auxiliares do banco.
DELETE VARIABLES ind_1 ind_2 ind_3 ind_4 ind_5 top_1 top_2 top_3 top_4 top_5 bot_1 bot_2 bot_3 bot_4 bot_5.
DATASET ACTIVATE agg.
* Percentuais de cor/raça com menos alunos que o limite (nmin) ficam em branco ("n baixo").
DO REPEAT p = pt_1 pt_2 pt_3 pt_4 pt_5 / b = pb_1 pb_2 pb_3 pb_4 pb_5 / q = n_1 n_2 n_3 n_4 n_5.
  IF (q < !nmin) p = $SYSMIS.
  IF (q < !nmin) b = $SYSMIS.
END REPEAT.
VARIABLE LABELS pt_1 'Branca' pt_2 'Preta' pt_3 'Parda' pt_4 'Amarela' pt_5 'Indígena' pt_t 'Todos'
  pb_1 'Branca' pb_2 'Preta' pb_3 'Parda' pb_4 'Amarela' pb_5 'Indígena' pb_t 'Todos'.
FORMATS pt_1 pt_2 pt_3 pt_4 pt_5 pt_t pb_1 pb_2 pb_3 pb_4 pb_5 pb_t (F8.3).
EXECUTE.
SUMMARIZE
  /TABLES=renda8 pt_1 pt_2 pt_3 pt_4 pt_5 pt_t
  /FORMAT=LIST NOCASENUM NOTOTAL MISSING='n baixo'
  /TITLE='Percentual de alunos entre os 25% maiores notas, por faixa de renda e cor/raça'
  /FOOTNOTE='n baixo: menos de 100 alunos do grupo na faixa (percentual não exibido). Todos: todos os alunos da faixa.'
  /MISSING=VARIABLE
  /CELLS=NONE.
SUMMARIZE
  /TABLES=renda8 pb_1 pb_2 pb_3 pb_4 pb_5 pb_t
  /FORMAT=LIST NOCASENUM NOTOTAL MISSING='n baixo'
  /TITLE='Percentual de alunos entre os 25% menores notas, por faixa de renda e cor/raça'
  /FOOTNOTE='n baixo: menos de 100 alunos do grupo na faixa (percentual não exibido). Todos: todos os alunos da faixa.'
  /MISSING=VARIABLE
  /CELLS=NONE.
DATASET ACTIVATE enem.
DATASET CLOSE agg.
*
* =====================================================================.
* BLOCO 8. RENDA FIXA, ESCOLARIDADE DOS PAIS VARIANDO, POR COR/RAÇA.
* Cada linha compara alunos da mesma faixa de renda e do mesmo nível de escolaridade dos pais.
* Colunas: nota média de cada cor/raça e diferença em pontos em relação aos brancos (negativa = média menor).
* =====================================================================.
* Para cada cor/raça (1 = Branca ... 5 = Indígena), cria um indicador (ind_k) e a nota só desse grupo (nota_k).
DO REPEAT ind = ind_1 ind_2 ind_3 ind_4 ind_5 / nota = nota_1 nota_2 nota_3 nota_4 nota_5 / k = 1 2 3 4 5.
  COMPUTE ind = (cor_raca = k).
  IF (cor_raca = k) nota = NU_NOTA_MT.
END REPEAT.
EXECUTE.
* Resume cada combinação de faixa de renda x escolaridade dos pais: número de alunos (n_k) e média (media_k) de cada cor/raça.
DATASET DECLARE agg.
AGGREGATE
  /OUTFILE=agg
  /BREAK=renda8 esc_pais
  /n_1=SUM(ind_1) /n_2=SUM(ind_2) /n_3=SUM(ind_3) /n_4=SUM(ind_4) /n_5=SUM(ind_5)
  /media_1=MEAN(nota_1) /media_2=MEAN(nota_2) /media_3=MEAN(nota_3) /media_4=MEAN(nota_4) /media_5=MEAN(nota_5).
* Remove as variáveis auxiliares do banco.
DELETE VARIABLES ind_1 ind_2 ind_3 ind_4 ind_5 nota_1 nota_2 nota_3 nota_4 nota_5.
DATASET ACTIVATE agg.
* Médias de cor/raça com menos alunos que o limite (nmin) ficam em branco ("n baixo").
DO REPEAT m = media_1 media_2 media_3 media_4 media_5 / q = n_1 n_2 n_3 n_4 n_5.
  IF (q < !nmin) m = $SYSMIS.
END REPEAT.
* Diferença em pontos em relação aos brancos.
COMPUTE dif_preta = media_2 - media_1.
COMPUTE dif_parda = media_3 - media_1.
COMPUTE dif_amarela = media_4 - media_1.
COMPUTE dif_indigena = media_5 - media_1.
VARIABLE LABELS media_1 'Média Branca' media_2 'Média Preta' media_3 'Média Parda'
  media_4 'Média Amarela' media_5 'Média Indígena'
  dif_preta 'Preta - Branca' dif_parda 'Parda - Branca' dif_amarela 'Amarela - Branca' dif_indigena 'Indígena - Branca'
  n_1 'N Branca' n_2 'N Preta' n_3 'N Parda' n_4 'N Amarela' n_5 'N Indígena'.
FORMATS media_1 media_2 media_3 media_4 media_5 dif_preta dif_parda dif_amarela dif_indigena (F8.3).
FORMATS n_1 n_2 n_3 n_4 n_5 (F8.0).
EXECUTE.
SUMMARIZE
  /TABLES=renda8 esc_pais media_1 media_2 media_3 media_4 media_5 dif_preta dif_parda dif_amarela dif_indigena
  /FORMAT=LIST NOCASENUM NOTOTAL MISSING='n baixo'
  /TITLE='Nota média por faixa de renda, escolaridade dos pais e cor/raça'
  /FOOTNOTE='n baixo: menos de 100 alunos do grupo na linha (média e diferença não exibidas). Diferença em pontos: negativa = média menor que a dos brancos.'
  /MISSING=VARIABLE
  /CELLS=NONE.
SUMMARIZE
  /TABLES=renda8 esc_pais n_1 n_2 n_3 n_4 n_5
  /FORMAT=LIST NOCASENUM NOTOTAL
  /TITLE='Número de alunos por faixa de renda, escolaridade dos pais e cor/raça'
  /MISSING=VARIABLE
  /CELLS=NONE.
DATASET ACTIVATE enem.
DATASET CLOSE agg.
*
* =====================================================================.
* BLOCO 9. RENDA FIXA, TIPO DE ESCOLA VARIANDO, POR COR/RAÇA.
* Cada linha compara alunos da mesma faixa de renda e do mesmo tipo de escola (pública ou privada).
* Colunas: nota média de cada cor/raça e diferença em pontos em relação aos brancos (negativa = média menor).
* =====================================================================.
* Para cada cor/raça (1 = Branca ... 5 = Indígena), cria um indicador (ind_k) e a nota só desse grupo (nota_k).
DO REPEAT ind = ind_1 ind_2 ind_3 ind_4 ind_5 / nota = nota_1 nota_2 nota_3 nota_4 nota_5 / k = 1 2 3 4 5.
  COMPUTE ind = (cor_raca = k).
  IF (cor_raca = k) nota = NU_NOTA_MT.
END REPEAT.
EXECUTE.
* Resume cada combinação de faixa de renda x tipo de escola: número de alunos (n_k) e média (media_k) de cada cor/raça.
DATASET DECLARE agg.
AGGREGATE
  /OUTFILE=agg
  /BREAK=renda8 escola
  /n_1=SUM(ind_1) /n_2=SUM(ind_2) /n_3=SUM(ind_3) /n_4=SUM(ind_4) /n_5=SUM(ind_5)
  /media_1=MEAN(nota_1) /media_2=MEAN(nota_2) /media_3=MEAN(nota_3) /media_4=MEAN(nota_4) /media_5=MEAN(nota_5).
* Remove as variáveis auxiliares do banco.
DELETE VARIABLES ind_1 ind_2 ind_3 ind_4 ind_5 nota_1 nota_2 nota_3 nota_4 nota_5.
DATASET ACTIVATE agg.
* Médias de cor/raça com menos alunos que o limite (nmin) ficam em branco ("n baixo").
DO REPEAT m = media_1 media_2 media_3 media_4 media_5 / q = n_1 n_2 n_3 n_4 n_5.
  IF (q < !nmin) m = $SYSMIS.
END REPEAT.
* Diferença em pontos em relação aos brancos.
COMPUTE dif_preta = media_2 - media_1.
COMPUTE dif_parda = media_3 - media_1.
COMPUTE dif_amarela = media_4 - media_1.
COMPUTE dif_indigena = media_5 - media_1.
VARIABLE LABELS media_1 'Média Branca' media_2 'Média Preta' media_3 'Média Parda'
  media_4 'Média Amarela' media_5 'Média Indígena'
  dif_preta 'Preta - Branca' dif_parda 'Parda - Branca' dif_amarela 'Amarela - Branca' dif_indigena 'Indígena - Branca'
  n_1 'N Branca' n_2 'N Preta' n_3 'N Parda' n_4 'N Amarela' n_5 'N Indígena'.
FORMATS media_1 media_2 media_3 media_4 media_5 dif_preta dif_parda dif_amarela dif_indigena (F8.3).
FORMATS n_1 n_2 n_3 n_4 n_5 (F8.0).
EXECUTE.
SUMMARIZE
  /TABLES=renda8 escola media_1 media_2 media_3 media_4 media_5 dif_preta dif_parda dif_amarela dif_indigena
  /FORMAT=LIST NOCASENUM NOTOTAL MISSING='n baixo'
  /TITLE='Nota média por faixa de renda, tipo de escola e cor/raça'
  /FOOTNOTE='n baixo: menos de 100 alunos do grupo na linha (média e diferença não exibidas). Diferença em pontos: negativa = média menor que a dos brancos.'
  /MISSING=VARIABLE
  /CELLS=NONE.
SUMMARIZE
  /TABLES=renda8 escola n_1 n_2 n_3 n_4 n_5
  /FORMAT=LIST NOCASENUM NOTOTAL
  /TITLE='Número de alunos por faixa de renda, tipo de escola e cor/raça'
  /MISSING=VARIABLE
  /CELLS=NONE.
DATASET ACTIVATE enem.
DATASET CLOSE agg.
*
* =====================================================================.
* FIM. Reativa as tabelas de resumo e desliga o filtro.
* =====================================================================.
OMSEND TAG=['ocultar_resumo'].
FILTER OFF.
USE ALL.
