* Encoding: UTF-8.
* =====================================================================.
* ENEM 2023 - NOTA DE MATEMÁTICA: TAMANHO DO EFEITO DA COR/RAÇA, DA RENDA FAMILIAR E DO TIPO DE ESCOLA.
* ANOVA de uma via, eta quadrado e d de Cohen entre todos os pares de grupos. Compatível com SPSS 22.
* =====================================================================.
*
* COMO USAR.
* 1) Abra o banco .sav completo (File > Open > Data).
* 2) Abra este arquivo de sintaxe e execute tudo (Run > All).
* O script é independente do tratamento descritivo e não altera o banco aberto (trabalha em uma cópia).
*
* VARIÁVEIS ANALISADAS (todas contra a nota de Matemática).
*   Cor/raça (5 grupos), faixa de renda familiar (8 faixas; SM = salário mínimo) e tipo de escola (pública e privada).
*
* O QUE O SCRIPT PRODUZ.
*   Tabela 1  Nota de Matemática por grupo: alunos, média e desvio padrão (uma tabela por variável).
*   Tabela 2  ANOVA de uma via, com teste de homogeneidade de variâncias e testes robustos (Welch e Brown-Forsythe).
*   Tabela 3  Tamanho do efeito global: eta quadrado e ômega quadrado das três variáveis.
*   Tabela 4  d de Cohen entre todos os pares de grupos, em matriz (cor/raça e renda; tipo de escola tem um único par).
*   Tabela 5  Os mesmos pares em lista, do maior para o menor d, sempre como maior média menos menor média.
*   Tabela 6  Modelo com as três variáveis juntas (ANOVA fatorial, soma de quadrados tipo III): eta quadrado parcial e médias ajustadas.
*   Tabela 7  Efeito de cada variável isolado, parcial e exclusivo, e variância compartilhada entre as variáveis.
*   Tabela 8  d de Cohen entre pares de cor/raça controlando renda e tipo de escola.
*   Tabela 9  d de Cohen bruto e controlando renda e tipo de escola, par a par, e quanto a diferença diminui.
*
* AMOSTRA ANALISADA. A mesma do tratamento descritivo (amostra_A = 1): concluintes presentes na prova de Matemática,
* sem treineiros, com cor/raça declarada (Branca, Preta, Parda, Amarela ou Indígena), tipo de escola, sexo, renda
* e escolaridade dos pais informados e nota maior que zero.
*
* TAMANHO DO EFEITO.
*   Eta quadrado = soma de quadrados entre grupos / soma de quadrados total (proporção da variância explicada).
*   d de Cohen = (média do grupo A - média do grupo B) / desvio padrão combinado dos dois grupos.
*   Eta quadrado parcial = soma de quadrados tipo III da variável / (soma de quadrados tipo III + soma de quadrados do erro).
*   Variância exclusiva = soma de quadrados tipo III da variável / soma de quadrados total (parte que só ela explica).
*   Referências de Cohen: d de 0,2 pequeno, 0,5 médio, 0,8 grande; eta quadrado de 0,01 pequeno, 0,06 médio, 0,14 grande.
*
* =====================================================================.
* 0. CONFIGURAÇÃO.
* =====================================================================.
FILTER OFF.
USE ALL.
DATASET NAME enem.
* Oculta as tabelas "Resumo de processamento de casos".
OMS
  /SELECT TABLES
  /IF SUBTYPES=['Case Processing Summary']
  /DESTINATION VIEWER=NO
  /TAG='ocultar_resumo_efeito'.
* Nomes dos grupos de cada variável (fator 1 = cor/raça, 2 = faixa de renda familiar, 3 = tipo de escola).
DEFINE !rotulos (grupo = !TOKENS(1) / rotulo = !TOKENS(1))
DO IF (fator = 1).
  RECODE !grupo (1='Branca') (2='Preta') (3='Parda') (4='Amarela') (5='Indígena') INTO !rotulo.
ELSE IF (fator = 2).
  RECODE !grupo (1='Até 1 SM') (2='1 a 1,5 SM') (3='1,5 a 2 SM') (4='2 a 2,5 SM') (5='2,5 a 3 SM')
    (6='3 a 4 SM') (7='4 a 5 SM') (8='Mais de 5 SM') INTO !rotulo.
ELSE IF (fator = 3).
  RECODE !grupo (1='Pública') (2='Privada') INTO !rotulo.
END IF
!ENDDEFINE.
*
* =====================================================================.
* 1. AMOSTRA E VARIÁVEIS (em uma cópia reduzida do banco).
* =====================================================================.
DATASET COPY efeito.
DATASET ACTIVATE efeito.
MATCH FILES
  /FILE=*
  /KEEP=TP_PRESENCA_MT IN_TREINEIRO TP_ST_CONCLUSAO TP_COR_RACA TP_ESCOLA TP_SEXO Q001 Q002 Q006 NU_NOTA_MT.
SELECT IF (TP_PRESENCA_MT = 1 AND IN_TREINEIRO = 0 AND TP_ST_CONCLUSAO = 2
  AND ANY(TP_COR_RACA, 1, 2, 3, 4, 5) AND ANY(TP_ESCOLA, 2, 3) AND ANY(TP_SEXO, 'F', 'M')
  AND ANY(Q006, 'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q')
  AND ANY(Q001, 'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H')
  AND ANY(Q002, 'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H')
  AND NU_NOTA_MT > 0).
* Cor/raça (1 a 5), faixa de renda (1 a 8: A-B, C, D, E, F, G, H, I-Q) e tipo de escola (1 = pública, 2 = privada).
RECODE TP_COR_RACA (1 THRU 5=COPY) (ELSE=SYSMIS) INTO cor_raca.
RECODE Q006 ('A','B'=1) ('C'=2) ('D'=3) ('E'=4) ('F'=5) ('G'=6) ('H'=7)
  ('I','J','K','L','M','N','O','P','Q'=8) (ELSE=SYSMIS) INTO renda8.
RECODE TP_ESCOLA (2=1) (3=2) (ELSE=SYSMIS) INTO escola.
FORMATS cor_raca renda8 escola (F1.0).
VARIABLE LABELS cor_raca 'Cor/raça' renda8 'Faixa de renda familiar' escola 'Tipo de escola'.
VALUE LABELS cor_raca 1 'Branca' 2 'Preta' 3 'Parda' 4 'Amarela' 5 'Indígena'
  /renda8 1 'Até 1 SM' 2 '1 a 1,5 SM' 3 '1,5 a 2 SM' 4 '2 a 2,5 SM' 5 '2,5 a 3 SM' 6 '3 a 4 SM' 7 '4 a 5 SM' 8 'Mais de 5 SM'
  /escola 1 'Pública' 2 'Privada'.
* Uma cópia da nota para cada variável, com o rótulo que identifica a variável nas tabelas da ANOVA.
COMPUTE nota_cor = NU_NOTA_MT.
COMPUTE nota_renda = NU_NOTA_MT.
COMPUTE nota_escola = NU_NOTA_MT.
COMPUTE nota_modelo = NU_NOTA_MT.
VARIABLE LABELS nota_cor 'Nota de Matemática por cor/raça'
  nota_renda 'Nota de Matemática por faixa de renda familiar'
  nota_escola 'Nota de Matemática por tipo de escola'
  nota_modelo 'Nota de Matemática: modelo com cor/raça, renda familiar e tipo de escola'.
FORMATS NU_NOTA_MT nota_cor nota_renda nota_escola nota_modelo (F8.1).
EXECUTE.
*
* =====================================================================.
* 2. TABELA 1: ALUNOS, MÉDIA E DESVIO PADRÃO POR GRUPO.
* =====================================================================.
* grp reúne os grupos das três variáveis: fator (1, 2 ou 3), g (código do grupo), n, média e desvio padrão.
DATASET DECLARE grp.
DATASET DECLARE g2.
DATASET DECLARE g3.
AGGREGATE
  /OUTFILE=grp
  /BREAK=cor_raca
  /n=N
  /media=MEAN(NU_NOTA_MT)
  /dp=SD(NU_NOTA_MT).
AGGREGATE
  /OUTFILE=g2
  /BREAK=renda8
  /n=N
  /media=MEAN(NU_NOTA_MT)
  /dp=SD(NU_NOTA_MT).
AGGREGATE
  /OUTFILE=g3
  /BREAK=escola
  /n=N
  /media=MEAN(NU_NOTA_MT)
  /dp=SD(NU_NOTA_MT).
DATASET ACTIVATE g2.
COMPUTE fator = 2.
COMPUTE g = renda8.
EXECUTE.
DATASET ACTIVATE g3.
COMPUTE fator = 3.
COMPUTE g = escola.
EXECUTE.
DATASET ACTIVATE grp.
COMPUTE fator = 1.
COMPUTE g = cor_raca.
EXECUTE.
ADD FILES
  /FILE=*
  /FILE=g2
  /FILE=g3
  /KEEP=fator g n media dp.
DATASET CLOSE g2.
DATASET CLOSE g3.
STRING rot (A30).
!rotulos grupo=g rotulo=rot.
VARIABLE LABELS n 'Alunos' media 'Nota média' dp 'Desvio padrão'.
FORMATS n (DOT9.0) media dp (F8.3).
EXECUTE.
VARIABLE LABELS rot 'Cor/raça'.
TEMPORARY.
SELECT IF (fator = 1).
SUMMARIZE
  /TABLES=rot n media dp
  /FORMAT=LIST NOCASENUM NOTOTAL
  /TITLE='Nota de Matemática por cor/raça: alunos, média e desvio padrão'
  /MISSING=VARIABLE
  /CELLS=NONE.
VARIABLE LABELS rot 'Faixa de renda familiar'.
TEMPORARY.
SELECT IF (fator = 2).
SUMMARIZE
  /TABLES=rot n media dp
  /FORMAT=LIST NOCASENUM NOTOTAL
  /TITLE='Nota de Matemática por faixa de renda familiar: alunos, média e desvio padrão'
  /FOOTNOTE='SM = salário mínimo.'
  /MISSING=VARIABLE
  /CELLS=NONE.
VARIABLE LABELS rot 'Tipo de escola'.
TEMPORARY.
SELECT IF (fator = 3).
SUMMARIZE
  /TABLES=rot n media dp
  /FORMAT=LIST NOCASENUM NOTOTAL
  /TITLE='Nota de Matemática por tipo de escola: alunos, média e desvio padrão'
  /MISSING=VARIABLE
  /CELLS=NONE.
*
* =====================================================================.
* 3. TABELA 2: ANOVA DE UMA VIA.
* =====================================================================.
DATASET ACTIVATE efeito.
ONEWAY nota_cor BY cor_raca
  /STATISTICS=HOMOGENEITY BROWNFORSYTHE WELCH
  /MISSING=ANALYSIS.
ONEWAY nota_renda BY renda8
  /STATISTICS=HOMOGENEITY BROWNFORSYTHE WELCH
  /MISSING=ANALYSIS.
ONEWAY nota_escola BY escola
  /STATISTICS=HOMOGENEITY BROWNFORSYTHE WELCH
  /MISSING=ANALYSIS.
*
* =====================================================================.
* 4. TABELA 3: ETA QUADRADO E ÔMEGA QUADRADO.
* =====================================================================.
DATASET ACTIVATE grp.
* Soma de quadrados entre grupos (sq_entre) e dentro dos grupos (sq_dentro), a partir de n, média e desvio padrão.
COMPUTE nm = n * media.
AGGREGATE
  /OUTFILE=* MODE=ADDVARIABLES
  /BREAK=fator
  /n_total=SUM(n)
  /soma_nm=SUM(nm)
  /ngrupos=N.
COMPUTE media_geral = soma_nm / n_total.
COMPUTE sq_e = n * (media - media_geral)**2.
COMPUTE sq_d = (n - 1) * dp**2.
EXECUTE.
DATASET DECLARE es.
AGGREGATE
  /OUTFILE=es
  /BREAK=fator
  /n_total=MAX(n_total)
  /ngrupos=MAX(ngrupos)
  /sq_entre=SUM(sq_e)
  /sq_dentro=SUM(sq_d).
DATASET ACTIVATE es.
COMPUTE sq_total = sq_entre + sq_dentro.
COMPUTE eta2 = sq_entre / sq_total.
COMPUTE pct_var = 100 * eta2.
COMPUTE mq_dentro = sq_dentro / (n_total - ngrupos).
COMPUTE omega2 = (sq_entre - (ngrupos - 1) * mq_dentro) / (sq_total + mq_dentro).
STRING variavel (A30).
STRING magnitude (A14).
RECODE fator (1='Cor/raça') (2='Renda familiar') (3='Tipo de escola') INTO variavel.
DO IF (eta2 < 0.01).
  COMPUTE magnitude = 'Desprezível'.
ELSE IF (eta2 < 0.06).
  COMPUTE magnitude = 'Pequeno'.
ELSE IF (eta2 < 0.14).
  COMPUTE magnitude = 'Médio'.
ELSE.
  COMPUTE magnitude = 'Grande'.
END IF.
VARIABLE LABELS variavel 'Variável analisada' ngrupos 'Grupos' n_total 'Alunos analisados'
  sq_entre 'Soma de quadrados entre grupos' sq_total 'Soma de quadrados total'
  eta2 'Eta quadrado' pct_var 'Variância explicada (%)' omega2 'Ômega quadrado' magnitude 'Magnitude do eta quadrado'.
FORMATS ngrupos (F2.0) n_total (DOT9.0) sq_entre sq_total (DOT16.0) eta2 pct_var omega2 (F8.3).
EXECUTE.
SUMMARIZE
  /TABLES=variavel ngrupos n_total sq_entre sq_total eta2 pct_var omega2 magnitude
  /FORMAT=LIST NOCASENUM NOTOTAL
  /TITLE='Tamanho do efeito global de cada variável sobre a nota de Matemática'
  /FOOTNOTE='Eta quadrado = soma de quadrados entre grupos / soma de quadrados total. Ômega quadrado: versão com menos viés. Cohen: 0,01 pequeno; 0,06 médio; 0,14 grande.'
  /MISSING=VARIABLE
  /CELLS=NONE.
DATASET ACTIVATE grp.
DATASET CLOSE es.
*
* =====================================================================.
* 5. TABELA 4: MATRIZ DO D DE COHEN ENTRE PARES DE GRUPOS.
* =====================================================================.
* Copia n, média e desvio padrão de cada grupo (1 a 8) para todas as linhas da mesma variável (n_j, m_j, s_j).
DO REPEAT j = 1 2 3 4 5 6 7 8
  / tn = tn_1 tn_2 tn_3 tn_4 tn_5 tn_6 tn_7 tn_8
  / tm = tm_1 tm_2 tm_3 tm_4 tm_5 tm_6 tm_7 tm_8
  / ts = ts_1 ts_2 ts_3 ts_4 ts_5 ts_6 ts_7 ts_8.
  IF (g = j) tn = n.
  IF (g = j) tm = media.
  IF (g = j) ts = dp.
END REPEAT.
EXECUTE.
AGGREGATE
  /OUTFILE=* MODE=ADDVARIABLES
  /BREAK=fator
  /n_1=MAX(tn_1) /n_2=MAX(tn_2) /n_3=MAX(tn_3) /n_4=MAX(tn_4) /n_5=MAX(tn_5) /n_6=MAX(tn_6) /n_7=MAX(tn_7) /n_8=MAX(tn_8)
  /m_1=MAX(tm_1) /m_2=MAX(tm_2) /m_3=MAX(tm_3) /m_4=MAX(tm_4) /m_5=MAX(tm_5) /m_6=MAX(tm_6) /m_7=MAX(tm_7) /m_8=MAX(tm_8)
  /s_1=MAX(ts_1) /s_2=MAX(ts_2) /s_3=MAX(ts_3) /s_4=MAX(ts_4) /s_5=MAX(ts_5) /s_6=MAX(ts_6) /s_7=MAX(ts_7) /s_8=MAX(ts_8).
* d de cada linha (grupo A) contra cada coluna (grupo B), só para B depois de A. d positivo: A tem a maior média.
DO REPEAT j = 1 2 3 4 5 6 7 8
  / nj = n_1 n_2 n_3 n_4 n_5 n_6 n_7 n_8
  / mj = m_1 m_2 m_3 m_4 m_5 m_6 m_7 m_8
  / sj = s_1 s_2 s_3 s_4 s_5 s_6 s_7 s_8
  / dj = d_1 d_2 d_3 d_4 d_5 d_6 d_7 d_8.
  IF (g < j) dj = (media - mj) / SQRT(((n - 1) * dp**2 + (nj - 1) * sj**2) / (n + nj - 2)).
END REPEAT.
FORMATS d_1 d_2 d_3 d_4 d_5 d_6 d_7 d_8 (F8.3).
EXECUTE.
VARIABLE LABELS rot 'Cor/raça (linha)' d_2 'Preta' d_3 'Parda' d_4 'Amarela' d_5 'Indígena'.
TEMPORARY.
SELECT IF (fator = 1 AND g < 5).
SUMMARIZE
  /TABLES=rot d_2 d_3 d_4 d_5
  /FORMAT=LIST NOCASENUM NOTOTAL MISSING='.'
  /TITLE='d de Cohen entre pares de cor/raça: nota de Matemática (linha contra coluna)'
  /FOOTNOTE='d = (média da linha - média da coluna) / desvio padrão combinado dos dois grupos. Positivo: a linha tem a maior média. Cohen: 0,2 pequeno; 0,5 médio; 0,8 grande.'
  /MISSING=VARIABLE
  /CELLS=NONE.
VARIABLE LABELS rot 'Faixa de renda (linha)' d_2 '1 a 1,5 SM' d_3 '1,5 a 2 SM' d_4 '2 a 2,5 SM' d_5 '2,5 a 3 SM'
  d_6 '3 a 4 SM' d_7 '4 a 5 SM' d_8 'Mais de 5 SM'.
TEMPORARY.
SELECT IF (fator = 2 AND g < 8).
SUMMARIZE
  /TABLES=rot d_2 d_3 d_4 d_5 d_6 d_7 d_8
  /FORMAT=LIST NOCASENUM NOTOTAL MISSING='.'
  /TITLE='d de Cohen entre faixas de renda familiar: nota de Matemática (linha contra coluna)'
  /FOOTNOTE='d = (média da linha - média da coluna) / desvio padrão combinado dos dois grupos. Positivo: a linha tem a maior média. SM = salário mínimo. Cohen: 0,2 pequeno; 0,5 médio; 0,8 grande.'
  /MISSING=VARIABLE
  /CELLS=NONE.
*
* =====================================================================.
* 6. TABELA 5: PARES EM LISTA, DO MAIOR PARA O MENOR D.
* =====================================================================.
VARSTOCASES
  /MAKE d FROM d_1 d_2 d_3 d_4 d_5 d_6 d_7 d_8
  /MAKE m_b FROM m_1 m_2 m_3 m_4 m_5 m_6 m_7 m_8
  /INDEX=g_b(8)
  /KEEP=fator g rot media
  /NULL=KEEP.
SELECT IF (NOT MISSING(d)).
STRING rot_b (A30).
!rotulos grupo=g_b rotulo=rot_b.
* Cada par fica como maior média (grupo A) menos menor média (grupo B), então d e a diferença são sempre positivos.
COMPUTE dif = media - m_b.
STRING maior menor (A30).
STRING magnitude (A14).
DO IF (dif >= 0).
  COMPUTE maior = rot.
  COMPUTE menor = rot_b.
ELSE.
  COMPUTE maior = rot_b.
  COMPUTE menor = rot.
END IF.
COMPUTE dif = ABS(dif).
COMPUTE d = ABS(d).
SORT CASES BY fator (A) d (D).
DO IF (d < 0.2).
  COMPUTE magnitude = 'Desprezível'.
ELSE IF (d < 0.5).
  COMPUTE magnitude = 'Pequeno'.
ELSE IF (d < 0.8).
  COMPUTE magnitude = 'Médio'.
ELSE.
  COMPUTE magnitude = 'Grande'.
END IF.
VARIABLE LABELS maior 'Grupo com maior média' menor 'Grupo com menor média' dif 'Diferença de médias (pontos)'
  d 'd de Cohen' magnitude 'Magnitude (Cohen)'.
FORMATS dif d (F8.3).
EXECUTE.
TEMPORARY.
SELECT IF (fator = 1).
SUMMARIZE
  /TABLES=maior menor dif d magnitude
  /FORMAT=LIST NOCASENUM NOTOTAL
  /TITLE='Cor/raça: pares de grupos em ordem decrescente do d de Cohen (nota de Matemática)'
  /FOOTNOTE='d = diferença de médias / desvio padrão combinado dos dois grupos. Cohen: 0,2 pequeno; 0,5 médio; 0,8 grande.'
  /MISSING=VARIABLE
  /CELLS=NONE.
TEMPORARY.
SELECT IF (fator = 2).
SUMMARIZE
  /TABLES=maior menor dif d magnitude
  /FORMAT=LIST NOCASENUM NOTOTAL
  /TITLE='Faixa de renda familiar: pares de grupos em ordem decrescente do d de Cohen (nota de Matemática)'
  /FOOTNOTE='d = diferença de médias / desvio padrão combinado dos dois grupos. SM = salário mínimo. Cohen: 0,2 pequeno; 0,5 médio; 0,8 grande.'
  /MISSING=VARIABLE
  /CELLS=NONE.
TEMPORARY.
SELECT IF (fator = 3).
SUMMARIZE
  /TABLES=maior menor dif d magnitude
  /FORMAT=LIST NOCASENUM NOTOTAL
  /TITLE='Tipo de escola: d de Cohen entre escola pública e privada (nota de Matemática)'
  /FOOTNOTE='d = diferença de médias / desvio padrão combinado dos dois grupos. Cohen: 0,2 pequeno; 0,5 médio; 0,8 grande.'
  /MISSING=VARIABLE
  /CELLS=NONE.
*
* =====================================================================.
* 7. TABELA 6: MODELO COM AS TRÊS VARIÁVEIS JUNTAS (ANOVA FATORIAL).
* =====================================================================.
* Efeito de cada variável controlando as outras duas (eta quadrado parcial) e médias de cor/raça ajustadas por renda e escola.
DATASET ACTIVATE efeito.
UNIANOVA nota_modelo BY cor_raca renda8 escola
  /METHOD=SSTYPE(3)
  /INTERCEPT=INCLUDE
  /EMMEANS=TABLES(cor_raca)
  /PRINT=ETASQ
  /CRITERIA=ALPHA(.05)
  /DESIGN=cor_raca renda8 escola.
*
* =====================================================================.
* 8. TABELAS 7 A 9: EFEITO ISOLADO, PARCIAL E EXCLUSIVO; D DE COHEN DE COR/RAÇA BRUTO E CONTROLADO.
* =====================================================================.
* Uma linha por combinação de cor/raça, renda e escola: n, média e soma de quadrados dentro da combinação.
AGGREGATE
  /OUTFILE=*
  /BREAK=cor_raca renda8 escola
  /n=N
  /media=MEAN(NU_NOTA_MT)
  /dp=SD(NU_NOTA_MT).
IF (MISSING(dp)) dp = 0.
COMPUTE ssw = (n - 1) * dp**2.
EXECUTE.
* O MATRIX ajusta, por mínimos quadrados ponderados por n, o modelo com as três variáveis, cada modelo sem uma delas,
* cada variável sozinha e o modelo sem variáveis (sse = soma de quadrados do erro de cada modelo).
* Resultado em bloco 1 (variáveis: isolado, parcial, exclusiva), bloco 2 (modelo conjunto), bloco 3 (matriz do d ajustado de cor/raça)
* e bloco 4 (cada par de cor/raça: d bruto e d ajustado).
MATRIX.
GET cel /FILE=* /VARIABLES=cor_raca renda8 escola n media ssw.
COMPUTE c = cel(:,1).
COMPUTE r = cel(:,2).
COMPUTE e = cel(:,3).
COMPUTE nn = cel(:,4).
COMPUTE y = cel(:,5).
COMPUTE sswt = CSUM(cel(:,6)).
COMPUTE ntot = CSUM(nn).
COMPUTE nc = NROW(cel).
COMPUTE W = MDIAG(nn).
COMPUTE um = MAKE(nc,1,1).
COMPUTE Xc = {(c = 1), (c = 2), (c = 3), (c = 4)}.
COMPUTE Xr = {(r = 1), (r = 2), (r = 3), (r = 4), (r = 5), (r = 6), (r = 7)}.
COMPUTE Xe = (e = 1).
COMPUTE inc = {1,1,1; 0,1,1; 1,0,1; 1,1,0; 1,0,0; 0,1,0; 0,0,1; 0,0,0}.
COMPUTE sse = MAKE(8,1,0).
LOOP m = 1 TO 8.
  COMPUTE X = um.
  DO IF (inc(m,1) = 1).
    COMPUTE X = {X, Xc}.
  END IF.
  DO IF (inc(m,2) = 1).
    COMPUTE X = {X, Xr}.
  END IF.
  DO IF (inc(m,3) = 1).
    COMPUTE X = {X, Xe}.
  END IF.
  COMPUTE beta = INV(T(X) * W * X) * T(X) * W * y.
  COMPUTE res = y - X * beta.
  COMPUTE sse(m) = sswt + T(res) * W * res.
  DO IF (m = 1).
    COMPUTE bfull = beta.
    COMPUTE gl = ntot - NCOL(X).
  END IF.
END LOOP.
COMPUTE sst = sse(8).
COMPUTE mse = sse(1) / gl.
COMPUTE iso = {1 - sse(5) / sst; 1 - sse(6) / sst; 1 - sse(7) / sst}.
COMPUTE parc = {(sse(2) - sse(1)) / sse(2); (sse(3) - sse(1)) / sse(3); (sse(4) - sse(1)) / sse(4)}.
COMPUTE excl = 100 * {(sse(2) - sse(1)) / sst; (sse(3) - sse(1)) / sst; (sse(4) - sse(1)) / sst}.
COMPUTE r2 = 100 * (1 - sse(1) / sst).
COMPUTE bcor = {bfull(2); bfull(3); bfull(4); bfull(5); 0}.
COMPUTE dadj = MAKE(5,5,0).
LOOP i = 1 TO 5.
  LOOP j = 1 TO 5.
    COMPUTE dadj(i,j) = (bcor(i) - bcor(j)) / SQRT(mse).
  END LOOP.
END LOOP.
COMPUTE ng = MAKE(5,1,0).
COMPUTE mg = MAKE(5,1,0).
COMPUTE ssg = MAKE(5,1,0).
LOOP k = 1 TO 5.
  COMPUTE sel = (c = k).
  COMPUTE ng(k) = CSUM(sel &* nn).
  COMPUTE mg(k) = CSUM(sel &* nn &* y) / ng(k).
  COMPUTE ssg(k) = CSUM(sel &* (cel(:,6) + nn &* (y - mg(k)) &** 2)).
END LOOP.
COMPUTE par = MAKE(10,4,0).
COMPUTE np = 0.
LOOP i = 1 TO 4.
  LOOP j = i + 1 TO 5.
    COMPUTE np = np + 1.
    COMPUTE sp = SQRT((ssg(i) + ssg(j)) / (ng(i) + ng(j) - 2)).
    COMPUTE par(np,1) = i.
    COMPUTE par(np,2) = j.
    COMPUTE par(np,3) = (mg(i) - mg(j)) / sp.
    COMPUTE par(np,4) = dadj(i,j).
  END LOOP.
END LOOP.
COMPUTE out = MAKE(19,7,-999).
COMPUTE out(1:3,1) = MAKE(3,1,1).
COMPUTE out(1:3,2) = {1; 2; 3}.
COMPUTE out(1:3,3) = iso.
COMPUTE out(1:3,4) = parc.
COMPUTE out(1:3,5) = excl.
COMPUTE out(4,1) = 2.
COMPUTE out(4,2) = 1.
COMPUTE out(4,3) = r2.
COMPUTE out(4,4) = CSUM(excl).
COMPUTE out(4,5) = r2 - CSUM(excl).
COMPUTE out(5:9,1) = MAKE(5,1,3).
COMPUTE out(5:9,2) = {1; 2; 3; 4; 5}.
COMPUTE out(5:9,3:7) = dadj.
COMPUTE out(10:19,1) = MAKE(10,1,4).
COMPUTE out(10:19,2) = par(:,1).
COMPUTE out(10:19,3) = par(:,2).
COMPUTE out(10:19,4) = par(:,3).
COMPUTE out(10:19,5) = par(:,4).
SAVE out /OUTFILE=* /VARIABLES=bloco linha v1 v2 v3 v4 v5.
END MATRIX.
RECODE v1 v2 v3 v4 v5 (-999=SYSMIS).
* Bloco 3: d ajustado de A (linha) contra B (coluna), só para B depois de A.
DO REPEAT j = 1 2 3 4 5 / vj = v1 v2 v3 v4 v5.
  IF (bloco = 3 AND linha >= j) vj = $SYSMIS.
END REPEAT.
STRING variavel rot rot_j maior menor (A30).
STRING magnitude (A14).
RECODE linha (1='Cor/raça') (2='Renda familiar') (3='Tipo de escola') INTO variavel.
RECODE linha (1='Branca') (2='Preta') (3='Parda') (4='Amarela') (5='Indígena') INTO rot.
RECODE v1 (1='Branca') (2='Preta') (3='Parda') (4='Amarela') (5='Indígena') INTO rot_j.
* Bloco 4: cada par fica como maior média bruta menos menor média bruta; o d ajustado segue a mesma orientação.
DO IF (bloco = 4).
  COMPUTE d_br = ABS(v2).
  DO IF (v2 >= 0).
    COMPUTE maior = rot.
    COMPUTE menor = rot_j.
    COMPUTE d_aj = v3.
  ELSE.
    COMPUTE maior = rot_j.
    COMPUTE menor = rot.
    COMPUTE d_aj = -v3.
  END IF.
  COMPUTE reducao = 100 * (d_br - d_aj) / d_br.
END IF.
COMPUTE ordem = linha.
IF (bloco = 4) ordem = -d_br.
SORT CASES BY bloco (A) ordem (A).
DO IF (bloco = 1).
  DO IF (v2 < 0.01).
    COMPUTE magnitude = 'Desprezível'.
  ELSE IF (v2 < 0.06).
    COMPUTE magnitude = 'Pequeno'.
  ELSE IF (v2 < 0.14).
    COMPUTE magnitude = 'Médio'.
  ELSE.
    COMPUTE magnitude = 'Grande'.
  END IF.
END IF.
FORMATS v1 v2 v3 v4 v5 d_br d_aj reducao (F8.3).
EXECUTE.
VARIABLE LABELS variavel 'Variável analisada' v1 'Eta quadrado isolado' v2 'Eta quadrado parcial (controlando as outras duas)'
  v3 'Variância exclusiva da variável (%)' magnitude 'Magnitude do eta quadrado parcial'.
TEMPORARY.
SELECT IF (bloco = 1).
SUMMARIZE
  /TABLES=variavel v1 v2 v3 magnitude
  /FORMAT=LIST NOCASENUM NOTOTAL
  /TITLE='Efeito de cada variável sobre a nota de Matemática: isolado e controlando as outras duas'
  /FOOTNOTE='Isolado: a variável sozinha. Parcial: parte da variância não explicada pelas outras duas que a variável explica. Exclusiva: parte da variância total que só ela explica. Cohen: 0,01 pequeno; 0,06 médio; 0,14 grande.'
  /MISSING=VARIABLE
  /CELLS=NONE.
VARIABLE LABELS v1 'Variância explicada pelas três variáveis juntas (%)' v2 'Soma das partes exclusivas (%)'
  v3 'Parte compartilhada entre as variáveis (%)'.
TEMPORARY.
SELECT IF (bloco = 2).
SUMMARIZE
  /TABLES=v1 v2 v3
  /FORMAT=LIST NOCASENUM NOTOTAL
  /TITLE='Variância da nota de Matemática explicada por cor/raça, renda familiar e tipo de escola'
  /FOOTNOTE='Parte compartilhada = variância explicada pelas três juntas - soma das partes exclusivas.'
  /MISSING=VARIABLE
  /CELLS=NONE.
VARIABLE LABELS rot 'Cor/raça (linha)' v2 'Preta' v3 'Parda' v4 'Amarela' v5 'Indígena'.
TEMPORARY.
SELECT IF (bloco = 3 AND linha < 5).
SUMMARIZE
  /TABLES=rot v2 v3 v4 v5
  /FORMAT=LIST NOCASENUM NOTOTAL MISSING='.'
  /TITLE='d de Cohen entre pares de cor/raça controlando renda e tipo de escola (linha contra coluna)'
  /FOOTNOTE='d = diferença de médias ajustada pelas outras duas variáveis / desvio padrão residual do modelo. Positivo: a linha tem a maior média ajustada. Cohen: 0,2 pequeno; 0,5 médio; 0,8 grande.'
  /MISSING=VARIABLE
  /CELLS=NONE.
VARIABLE LABELS maior 'Grupo com maior média' menor 'Grupo com menor média' d_br 'd de Cohen bruto'
  d_aj 'd de Cohen controlando renda e escola' reducao 'Redução do d (%)'.
TEMPORARY.
SELECT IF (bloco = 4).
SUMMARIZE
  /TABLES=maior menor d_br d_aj reducao
  /FORMAT=LIST NOCASENUM NOTOTAL
  /TITLE='Cor/raça: d de Cohen bruto e controlando renda e tipo de escola, por par de grupos'
  /FOOTNOTE='d bruto = diferença de médias / desvio padrão combinado do par. d ajustado = diferença ajustada por renda e escola / desvio padrão residual do modelo. Redução = parte do d bruto que some com o controle.'
  /MISSING=VARIABLE
  /CELLS=NONE.
*
* =====================================================================.
* FIM. Fecha os conjuntos auxiliares e reativa as tabelas de resumo.
* =====================================================================.
DATASET ACTIVATE enem.
DATASET CLOSE efeito.
DATASET CLOSE grp.
OMSEND TAG=['ocultar_resumo_efeito'].
