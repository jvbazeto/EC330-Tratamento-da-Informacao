#!/usr/bin/env python3
"""
Gera um arquivo .sav (IBM SPSS Statistics) com um recorte do ENEM 2023 e as
respostas de Matemática reordenadas para um único caderno de referência
(Azul, CO_PROVA_MT = 1211).

Etapas:
  1. Lê MICRODADOS_ENEM_2023.csv (delimitador ";", sem tratamento de aspas)
  2. Mantém apenas as colunas de COLUNAS_MANTIDAS
  3. Aplica os filtros: presente em Matemática (TP_PRESENCA_MT = 1),
     não treineiro (IN_TREINEIRO = 0) e concluinte em 2023 (TP_ST_CONCLUSAO = 2)
  4. Lê ITENS_PROVA_2023.csv e confere que os cadernos 1211 (Azul), 1212
     (Amarela), 1213 (Rosa) e 1214 (Cinza) têm exatamente os mesmos 45 CO_ITEM
     do caderno de referência, com o mesmo gabarito item a item
  5. Reordena as respostas de cada aluno para a ordem do caderno de referência
  6. Cria RMT_1..45 (resposta), GMT_1..45 (gabarito) e ACERTO_RMT_1..45
  7. Grava o .sav com formatos, rótulos de variável e rótulos de valor

Colunas do arquivo final (além de RMT_, GMT_ e ACERTO_RMT_):
  NU_INSCRICAO, TP_SEXO, TP_COR_RACA, TP_ST_CONCLUSAO, TP_ANO_CONCLUIU,
  TP_FAIXA_ETARIA, TP_ESCOLA, TP_ENSINO, IN_TREINEIRO, CO_UF_ESC, SG_UF_ESC,
  TP_PRESENCA_MT, NU_NOTA_MT, Q001 a Q006 e as quatro colunas abaixo:
  TX_RESPOSTAS_MT       respostas já na ordem do caderno de referência
  TX_GABARITO_MT        gabarito do caderno de referência (igual para todos)
  TX_RESPOSTAS_MT_ORIG  respostas como vieram no CSV, na ordem do caderno do aluno
  CO_PROVA_MT           caderno que o aluno realmente fez; não é alterado

Também grava <saida>_correspondencia_itens.csv com a posição de cada item em
cada caderno, para conferência.

Uso:
  python gerar_sav_enem_2023.py MICRODADOS_ENEM_2023.csv
  python gerar_sav_enem_2023.py entrada.csv --itens ITENS_PROVA_2023.csv -o saida.sav

Dependências:
  pip install pandas numpy pyreadstat
"""

import argparse
import codecs
import csv
import sys
import time
from pathlib import Path

import numpy as np
import pandas as pd

try:
    import pyreadstat
except ImportError:
    sys.exit("Erro: falta a biblioteca pyreadstat (grava arquivos .sav).\n"
             "Instale com:  pip install pyreadstat")

# ----------------------------------------------------------------------------
# Configuração
# ----------------------------------------------------------------------------

ARQUIVO_ENTRADA = "MICRODADOS_ENEM_2023.csv"
NOME_ARQUIVO_ITENS = "ITENS_PROVA_2023.csv"
ARQUIVO_SAIDA = "enem_2023_MT_caderno_azul.sav"

CADERNO_REFERENCIA = "1211"
CADERNOS = ("1211", "1212", "1213", "1214")   # únicos aceitos
N_ITENS = 45

NOMES_CADERNOS = {"1211": "Azul", "1212": "Amarela", "1213": "Rosa", "1214": "Cinza"}

COLUNAS_MANTIDAS = [
    "NU_INSCRICAO",
    "TP_SEXO",
    "TP_COR_RACA",
    "TP_ST_CONCLUSAO",
    "TP_ANO_CONCLUIU",
    "TP_FAIXA_ETARIA",
    "TP_ESCOLA",
    "TP_ENSINO",
    "IN_TREINEIRO",
    "CO_UF_ESC",
    "SG_UF_ESC",
    "TP_PRESENCA_MT",
    "CO_PROVA_MT",
    "NU_NOTA_MT",
    "TX_RESPOSTAS_MT",
    "TX_GABARITO_MT",
    "Q001",
    "Q002",
    "Q003",
    "Q004",
    "Q005",
    "Q006",
]

TAMANHO_PEDACO = 200_000
PADRAO_VETOR = rf"[A-Z.*]{{{N_ITENS}}}"           # 45 caracteres: letras, "." ou "*"

# Formato que começa com "A" = texto; qualquer outro = numérico.
FORMATOS = {
    "NU_INSCRICAO": "F21.0", "TP_SEXO": "A1", "TP_COR_RACA": "F1.0",
    "TP_ST_CONCLUSAO": "F1.0", "TP_ANO_CONCLUIU": "F2.0", "TP_FAIXA_ETARIA": "F2.0",
    "TP_ESCOLA": "F1.0", "TP_ENSINO": "F1.0", "IN_TREINEIRO": "F1.0",
    "CO_UF_ESC": "F2.0", "SG_UF_ESC": "A2",
    "TP_PRESENCA_MT": "F1.0", "CO_PROVA_MT": "F4.0", "NU_NOTA_MT": "COMMA8.2",
    "TX_RESPOSTAS_MT": f"A{N_ITENS}", "TX_GABARITO_MT": f"A{N_ITENS}",
    "TX_RESPOSTAS_MT_ORIG": f"A{N_ITENS}",
    "Q001": "A1", "Q002": "A1", "Q003": "A1", "Q004": "A1",   # Q004 aparece como "Numérica" no
    "Q005": "F2.0", "Q006": "A1",                             # dicionário, mas é letra A-F
}

ROTULOS_VARIAVEIS = {
    "NU_INSCRICAO": "Número de inscrição",
    "TP_SEXO": "Sexo",
    "TP_COR_RACA": "Cor/raça",
    "TP_ST_CONCLUSAO": "Situação de conclusão do Ensino Médio",
    "TP_ANO_CONCLUIU": "Ano de Conclusão do Ensino Médio",
    "TP_FAIXA_ETARIA": "Faixa etária",
    "TP_ESCOLA": "Tipo de escola do Ensino Médio",
    "TP_ENSINO": "Tipo de instituição que concluiu ou concluirá o Ensino Médio",
    "IN_TREINEIRO": "Indica se o inscrito fez a prova com intuito de apenas treinar seus conhecimentos",
    "CO_UF_ESC": "Código da Unidade da Federação da escola",
    "SG_UF_ESC": "Sigla da Unidade da Federação da escola",
    "TP_PRESENCA_MT": "Presença na prova objetiva de Matemática",
    "CO_PROVA_MT": "Código do tipo de prova de Matemática (caderno que o aluno fez)",
    "NU_NOTA_MT": "Nota da prova de Matemática",
    "TX_RESPOSTAS_MT": f"Respostas de Matemática reordenadas para o caderno {CADERNO_REFERENCIA}",
    "TX_GABARITO_MT": f"Gabarito de Matemática do caderno {CADERNO_REFERENCIA}",
    "TX_RESPOSTAS_MT_ORIG": "Respostas de Matemática originais, na ordem do caderno do aluno",
    "Q001": "Até que série seu pai, ou o homem responsável por você, estudou?",
    "Q002": "Até que série sua mãe, ou a mulher responsável por você, estudou?",
    # O rótulo oficial de Q003/Q004 tem ~290 caracteres; o SPSS aceita no máximo 256.
    "Q003": "Grupo de ocupação do pai ou do homem responsável (último trabalho, se não trabalha)",
    "Q004": "Grupo de ocupação da mãe ou da mulher responsável (último trabalho, se não trabalha)",
    "Q005": "Incluindo você, quantas pessoas moram atualmente em sua residência?",
    "Q006": "Qual é a renda mensal de sua família? (Some a sua renda com a dos seus familiares.)",
}

ESCOLARIDADE_PAIS = {      # Q001 (pai) e Q002 (mãe) usam as mesmas categorias
    "A": "Nunca estudou.",
    "B": "Não completou a 4ª série/5º ano do Ensino Fundamental.",
    "C": "Completou a 4ª série/5º ano, mas não completou a 8ª série/9º ano do Ensino Fundamental.",
    "D": "Completou a 8ª série/9º ano do Ensino Fundamental, mas não completou o Ensino Médio.",
    "E": "Completou o Ensino Médio, mas não completou a Faculdade.",
    "F": "Completou a Faculdade, mas não completou a Pós-graduação.",
    "G": "Completou a Pós-graduação.",
    "H": "Não sei.",
}

ROTULOS_VALORES = {
    "TP_SEXO": {"M": "Masculino", "F": "Feminino"},
    "TP_COR_RACA": {0: "Não declarado", 1: "Branca", 2: "Preta", 3: "Parda", 4: "Amarela",
                    5: "Indígena", 6: "Não dispõe da informação"},
    "TP_ST_CONCLUSAO": {1: "Já concluí o Ensino Médio",
                        2: "Estou cursando e concluirei o Ensino Médio em 2023",
                        3: "Estou cursando e concluirei o Ensino Médio após 2023",
                        4: "Não concluí e não estou cursando o Ensino Médio"},
    "TP_ANO_CONCLUIU": {0: "Não informado", 1: "2022", 2: "2021", 3: "2020", 4: "2019",
                        5: "2018", 6: "2017", 7: "2016", 8: "2015", 9: "2014", 10: "2013",
                        11: "2012", 12: "2011", 13: "2010", 14: "2009", 15: "2008",
                        16: "2007", 17: "Anterior a 2007"},
    "TP_FAIXA_ETARIA": {1: "Menor de 17 anos", 2: "17 anos", 3: "18 anos", 4: "19 anos",
                        5: "20 anos", 6: "21 anos", 7: "22 anos", 8: "23 anos", 9: "24 anos",
                        10: "25 anos", 11: "Entre 26 e 30 anos", 12: "Entre 31 e 35 anos",
                        13: "Entre 36 e 40 anos", 14: "Entre 41 e 45 anos",
                        15: "Entre 46 e 50 anos", 16: "Entre 51 e 55 anos",
                        17: "Entre 56 e 60 anos", 18: "Entre 61 e 65 anos",
                        19: "Entre 66 e 70 anos", 20: "Maior de 70 anos"},
    "TP_ESCOLA": {1: "Não respondeu", 2: "Pública", 3: "Privada"},
    "TP_ENSINO": {1: "Ensino Regular", 2: "Educação Especial - Modalidade Substitutiva"},
    "IN_TREINEIRO": {0: "Não", 1: "Sim"},
    "TP_PRESENCA_MT": {0: "Faltou à prova", 1: "Presente na prova", 2: "Eliminado na prova"},
    # Códigos do IBGE (o dicionário do INEP não traz rótulos para CO_UF_ESC).
    "CO_UF_ESC": {11: "Rondônia", 12: "Acre", 13: "Amazonas", 14: "Roraima", 15: "Pará",
                  16: "Amapá", 17: "Tocantins", 21: "Maranhão", 22: "Piauí", 23: "Ceará",
                  24: "Rio Grande do Norte", 25: "Paraíba", 26: "Pernambuco", 27: "Alagoas",
                  28: "Sergipe", 29: "Bahia", 31: "Minas Gerais", 32: "Espírito Santo",
                  33: "Rio de Janeiro", 35: "São Paulo", 41: "Paraná", 42: "Santa Catarina",
                  43: "Rio Grande do Sul", 50: "Mato Grosso do Sul", 51: "Mato Grosso",
                  52: "Goiás", 53: "Distrito Federal"},
    "Q001": ESCOLARIDADE_PAIS, "Q002": ESCOLARIDADE_PAIS,
    # Rótulos abreviados: o SPSS limita rótulo de valor a 120 bytes.
    "Q003": {"A": "Grupo 1: Lavrador, agricultor sem empregados, pescador, extrativista etc.",
             "B": "Grupo 2: Diarista, doméstico, porteiro, vigilante, vendedor, caixa, auxiliar adm. etc.",
             "C": "Grupo 3: Padeiro, cozinheiro, costureiro, operário, pedreiro, motorista, taxista etc.",
             "D": "Grupo 4: Professor (fund./médio), técnico, policial, gerente, microempresário, autônomo etc.",
             "E": "Grupo 5: Médico, engenheiro, advogado, juiz, prof. universitário, diretor, empresário (+10 empr.) etc.",
             "F": "Não sei."},
    "Q004": {"A": "Grupo 1: Lavradora, agricultora sem empregados, pescadora, extrativista etc.",
             "B": "Grupo 2: Diarista, doméstica, porteira, vigilante, vendedora, caixa, auxiliar adm. etc.",
             "C": "Grupo 3: Padeira, cozinheira, costureira, operária, pedreira, motorista, taxista etc.",
             "D": "Grupo 4: Professora (fund./médio), técnica, policial, gerente, microempresária, autônoma etc.",
             "E": "Grupo 5: Médica, engenheira, advogada, juíza, prof. universitária, diretora, empresária (+10 empr.) etc.",
             "F": "Não sei."},
    "Q005": {1: "1, pois moro sozinho(a)", **{k: str(k) for k in range(2, 21)}},
    "Q006": {"A": "Nenhuma Renda", "B": "Até R$ 1.320,00",
             "C": "De R$ 1.320,01 até R$ 1.980,00.", "D": "De R$ 1.980,01 até R$ 2.640,00.",
             "E": "De R$ 2.640,01 até R$ 3.300,00.", "F": "De R$ 3.300,01 até R$ 3.960,00.",
             "G": "De R$ 3.960,01 até R$ 5.280,00.", "H": "De R$ 5.280,01 até R$ 6.600,00.",
             "I": "De R$ 6.600,01 até R$ 7.920,00.", "J": "De R$ 7.920,01 até R$ 9240,00.",
             "K": "De R$ 9.240,01 até R$ 10.560,00.", "L": "De R$ 10.560,01 até R$ 11.880,00.",
             "M": "De R$ 11.880,01 até R$ 13.200,00.", "N": "De R$ 13.200,01 até R$ 15.840,00.",
             "O": "De R$ 15.840,01 até R$19.800,00.", "P": "De R$ 19.800,01 até R$ 26.400,00.",
             "Q": "Acima de R$ 26.400,00."},
}

MEDIDAS = {"NU_NOTA_MT": "scale"}                 # o resto é "nominal"


def sair(msg):
    sys.exit("\nERRO: " + msg)


# ----------------------------------------------------------------------------
# Leitura de CSV
# ----------------------------------------------------------------------------

def detectar_encoding(caminho):
    """
    Os arquivos do INEP vêm em cp1252, mas um CSV reprocessado (por Excel,
    Power BI ou por outro script) costuma vir em UTF-8 com BOM. Ler cp1252 num
    arquivo com BOM corrompe o nome da primeira coluna e derruba o script.
    """
    with open(caminho, "rb") as f:
        inicio = f.read(4)
    if inicio.startswith(codecs.BOM_UTF8):
        return "utf-8-sig"
    return "cp1252"


def ler_csv(caminho, **kwargs):
    """read_csv com o encoding detectado e queda para o outro em caso de erro."""
    encoding = kwargs.pop("encoding", None) or detectar_encoding(caminho)
    try:
        return pd.read_csv(caminho, encoding=encoding, **kwargs)
    except UnicodeDecodeError:
        alternativo = "cp1252" if encoding.startswith("utf") else "utf-8-sig"
        return pd.read_csv(caminho, encoding=alternativo, **kwargs)


# ----------------------------------------------------------------------------
# Correspondência entre cadernos (a partir de ITENS_PROVA_2023.csv)
# ----------------------------------------------------------------------------

def ler_itens(caminho):
    """Lê ITENS_PROVA_2023.csv como texto, sem espaços nas pontas."""
    df = ler_csv(caminho, sep=";", dtype=str, keep_default_na=False,
                 quoting=csv.QUOTE_NONE)
    df.columns = df.columns.str.strip()
    for c in df.columns:
        df[c] = df[c].str.strip()
    return df


def _conferir_caderno(d, itens_ref, gab_por_item):
    """Devolve o motivo da recusa, ou None se o caderno serve."""
    if len(d) != N_ITENS:
        return f"tem {len(d)} itens de Matemática (esperado: {N_ITENS})"
    if d["CO_POSICAO"].duplicated().any() or d["CO_ITEM"].duplicated().any():
        return "tem CO_POSICAO ou CO_ITEM repetido"
    if set(d["CO_ITEM"]) != set(itens_ref):
        return "não tem exatamente as mesmas 45 questões do caderno de referência"
    gab = dict(zip(d["CO_ITEM"], d["TX_GABARITO"]))
    diverge = [i for i in itens_ref if gab[i] != gab_por_item[i]]
    if diverge:
        return (f"{len(diverge)} questão(ões) com gabarito diferente do caderno de "
                f"referência (CO_ITEM {diverge[:5]}); as alternativas parecem ter "
                "ordem diferente e a reordenação por posição não valeria")
    return None


def montar_correspondencia(caminho_itens):
    """
    Lê ITENS_PROVA_2023.csv e confere que CADERNOS = 1211, 1212, 1213 e 1214 têm
    exatamente os mesmos 45 CO_ITEM do caderno de referência (1211), com o mesmo
    gabarito item a item. Para de imediato se algum não passar.

    Devolve um dicionário com:
      itens_ref : os 45 CO_ITEM do caderno de referência, na ordem da prova
      gab_ref   : o gabarito (1 letra) dessas 45 questões
      anulados  : vetor booleano (45) marcando itens anulados/abandonados
      perm      : {caderno: array} onde perm[c][j] = posição (0-44) que, no
                  caderno c, ocupa a questão j do caderno de referência
      tabela    : DataFrame de conferência
    """
    itens = ler_itens(caminho_itens)
    exigidas = {"CO_POSICAO", "SG_AREA", "CO_ITEM", "TX_GABARITO", "CO_PROVA", "IN_ITEM_ABAN"}
    faltando = exigidas - set(itens.columns)
    if faltando:
        sair(f"colunas não encontradas em {caminho_itens.name}: {', '.join(sorted(faltando))}")

    mt = itens[itens["SG_AREA"].str.upper() == "MT"].copy()
    mt["CO_POSICAO"] = pd.to_numeric(mt["CO_POSICAO"], errors="coerce")
    mt["TX_GABARITO"] = mt["TX_GABARITO"].str.upper()
    if mt["CO_POSICAO"].isna().any():
        sair("há CO_POSICAO não numérico nos itens de Matemática.")
    grupos = {c: d.sort_values("CO_POSICAO") for c, d in mt.groupby("CO_PROVA")}

    ref = grupos.get(CADERNO_REFERENCIA)
    if ref is None:
        sair(f"o caderno de referência {CADERNO_REFERENCIA} não está em {caminho_itens.name}.")
    itens_ref = ref["CO_ITEM"].tolist()
    gab_ref = ref["TX_GABARITO"].tolist()
    gab_por_item = dict(zip(itens_ref, gab_ref))

    # Item anulado: gabarito "X" ou IN_ITEM_ABAN = "1". Nesses itens o ACERTO
    # vira missing, porque o acerto não distingue os alunos.
    anulados = np.array([g == "X" for g in gab_ref]) | (ref["IN_ITEM_ABAN"] == "1").to_numpy()

    perm = {}
    for c in CADERNOS:
        d = grupos.get(c)
        motivo = ("não tem itens de Matemática no arquivo de itens" if d is None
                  else _conferir_caderno(d, itens_ref, gab_por_item))
        if motivo:
            sair(f"o caderno {c} {motivo}.")
        onde = {item: k for k, item in enumerate(d["CO_ITEM"].tolist())}
        perm[c] = np.array([onde[i] for i in itens_ref])

    tabela = pd.DataFrame({
        "POS_REFERENCIA": np.arange(1, N_ITENS + 1),
        "CO_ITEM": itens_ref,
        "TX_GABARITO": gab_ref,
        "IN_ANULADO": anulados.astype(int),
        "CO_HABILIDADE": ref["CO_HABILIDADE"].tolist() if "CO_HABILIDADE" in ref.columns else "",
    })
    for c in CADERNOS:
        tabela[f"POS_{c}"] = perm[c] + 1

    return {"itens_ref": itens_ref, "gab_ref": gab_ref, "anulados": anulados,
            "perm": perm, "tabela": tabela}


# ----------------------------------------------------------------------------
# Reordenação
# ----------------------------------------------------------------------------

def para_codigos(serie):
    """Série de textos com 45 caracteres -> matriz uint8 (n, 45) de códigos ASCII."""
    bruto = "".join(serie.tolist()).encode("ascii")
    return np.frombuffer(bruto, dtype=np.uint8).reshape(len(serie), N_ITENS)


def reordenar(codigos, provas, perm):
    """Reordena cada linha para a ordem do caderno de referência."""
    saida = np.zeros_like(codigos)
    atendidas = np.zeros(len(codigos), dtype=bool)
    for caderno, p in perm.items():
        m = provas == caderno
        if m.any():
            saida[m] = codigos[m][:, p]
            atendidas |= m
    if not atendidas.all():
        sair("há linhas com CO_PROVA_MT sem correspondência de itens; "
             "isso indica falha no filtro de cadernos.")
    return saida


# ----------------------------------------------------------------------------
# Programa principal
# ----------------------------------------------------------------------------

def main():
    ap = argparse.ArgumentParser(
        description="Gera o .sav do ENEM 2023 com Matemática reordenada para um único caderno.")
    ap.add_argument("entrada", nargs="?", default=ARQUIVO_ENTRADA,
                    help=f"CSV dos microdados (padrão: {ARQUIVO_ENTRADA})")
    ap.add_argument("--itens", default=None,
                    help=f"{NOME_ARQUIVO_ITENS} (padrão: mesma pasta do CSV de entrada)")
    ap.add_argument("-o", "--saida", default=ARQUIVO_SAIDA, help="arquivo .sav de saída")
    ap.add_argument("--branco-missing", action="store_true",
                    help="trata resposta em branco (\".\") como missing em ACERTO_RMT, "
                         "em vez de erro")
    ap.add_argument("--zsav", action="store_true",
                    help="grava .zsav (comprimido; exige SPSS 21 ou mais novo)")
    ap.add_argument("--ignorar-divergencia", action="store_true",
                    help="não interrompe se o gabarito reordenado divergir do gabarito de "
                         "referência (apenas avisa)")
    args = ap.parse_args()

    entrada = Path(args.entrada)
    itens_path = Path(args.itens) if args.itens else entrada.with_name(NOME_ARQUIVO_ITENS)
    saida = Path(args.saida).with_suffix(".zsav" if args.zsav else ".sav")
    for p, nome in ((entrada, "microdados"), (itens_path, "itens")):
        if not p.exists():
            sair(f"arquivo de {nome} não encontrado:\n  {p}\n"
                 "Passe o caminho correto (o de itens com --itens).")

    inicio = time.time()

    # --- Correspondência entre cadernos --------------------------------------
    print(f"Lendo itens: {itens_path}")
    corr = montar_correspondencia(itens_path)
    perm = corr["perm"]
    anulados = corr["anulados"]
    ref_gab = "".join(corr["gab_ref"])
    ref_cod = np.frombuffer(ref_gab.encode("ascii"), dtype=np.uint8)

    print("  cadernos: " + ", ".join(f"{c} ({NOMES_CADERNOS[c]})" for c in CADERNOS))
    if anulados.any():
        print(f"  {int(anulados.sum())} item(ns) anulado(s) nas posições "
              f"{[int(i) + 1 for i in np.where(anulados)[0]]}; ACERTO_RMT será missing neles.")

    caminho_tabela = saida.with_name(saida.stem + "_correspondencia_itens.csv")
    corr["tabela"].to_csv(caminho_tabela, sep=";", index=False, encoding="utf-8-sig")
    print(f"  tabela de conferência: {caminho_tabela.name}")

    # --- Leitura e filtro ----------------------------------------------------
    opcoes_leitura = dict(sep=";", encoding=detectar_encoding(entrada),
                          quoting=csv.QUOTE_NONE)

    cabecalho = pd.read_csv(entrada, nrows=0, **opcoes_leitura)
    faltando = [c for c in COLUNAS_MANTIDAS if c not in cabecalho.columns]
    if faltando:
        sair("colunas não encontradas no CSV: " + ", ".join(faltando))
    colunas_base = [c for c in cabecalho.columns if c in COLUNAS_MANTIDAS]  # ordem do arquivo
    colunas_num = [c for c in colunas_base if not FORMATOS.get(c, "A1").startswith("A")]
    colunas_dec = [c for c in colunas_num if c.startswith("NU_NOTA")]

    contagem = {"lidas": 0, "presentes em MT": 0, "não treineiros": 0,
                "concluintes 2023": 0, "cadernos aceitos": 0, "vetor de 45 válido": 0}
    partes, blocos_cod = [], []

    print(f"\nLendo: {entrada}  (encoding {opcoes_leitura['encoding']})")
    pedacos = pd.read_csv(
        entrada,
        usecols=COLUNAS_MANTIDAS,
        dtype=str,
        keep_default_na=False,
        chunksize=TAMANHO_PEDACO,
        **opcoes_leitura,
    )

    for i, df in enumerate(pedacos, start=1):
        contagem["lidas"] += len(df)

        df = df[df["TP_PRESENCA_MT"] == "1"]
        contagem["presentes em MT"] += len(df)

        df = df[df["IN_TREINEIRO"] == "0"]
        contagem["não treineiros"] += len(df)

        df = df[df["TP_ST_CONCLUSAO"] == "2"]
        contagem["concluintes 2023"] += len(df)

        df = df[df["CO_PROVA_MT"].isin(CADERNOS)]
        contagem["cadernos aceitos"] += len(df)

        df = df.copy()
        df["TX_RESPOSTAS_MT"] = df["TX_RESPOSTAS_MT"].str.strip()
        df["TX_GABARITO_MT"] = df["TX_GABARITO_MT"].str.strip()
        valido = (df["TX_RESPOSTAS_MT"].str.fullmatch(PADRAO_VETOR)
                  & df["TX_GABARITO_MT"].str.fullmatch(PADRAO_VETOR))
        df = df[valido].copy()
        contagem["vetor de 45 válido"] += len(df)

        provas = df["CO_PROVA_MT"].to_numpy()
        resp_ref = reordenar(para_codigos(df["TX_RESPOSTAS_MT"]), provas, perm)
        gab_ref_aluno = reordenar(para_codigos(df["TX_GABARITO_MT"]), provas, perm)

        # O gabarito de cada aluno, depois de reordenado, tem que virar o gabarito
        # de referência. Se não virar, a ordem dos itens no arquivo de itens não
        # corresponde à dos microdados e a reordenação está errada.
        dif = (gab_ref_aluno != ref_cod) & ~anulados
        if dif.any():
            por_caderno = pd.Series(provas[dif.any(axis=1)]).value_counts().to_dict()
            pos = [int(k) + 1 for k in np.where(dif.any(axis=0))[0]]
            msg = (f"o gabarito reordenado não bate com o do caderno {CADERNO_REFERENCIA}.\n"
                   f"  alunos afetados por caderno: {por_caderno}\n"
                   f"  posições com divergência: {pos}")
            if not args.ignorar_divergencia:
                sair(msg + "\n  (use --ignorar-divergencia só depois de investigar)")
            print("\n  AVISO: " + msg)

        df["TX_RESPOSTAS_MT_ORIG"] = df["TX_RESPOSTAS_MT"]
        df = df.drop(columns=["TX_RESPOSTAS_MT", "TX_GABARITO_MT"])  # refeitos a partir de resp_ref
        for c in colunas_num:
            s = df[c].str.strip()
            if c in colunas_dec:
                s = s.str.replace(",", ".", regex=False)
            df[c] = pd.to_numeric(s, errors="coerce")

        partes.append(df.reset_index(drop=True))
        blocos_cod.append(resp_ref)
        print(f"  pedaço {i}: {contagem['vetor de 45 válido']:,} linhas mantidas", end="\r")

    print("\n\nLinhas que sobraram em cada etapa:")
    for etapa, n in contagem.items():
        print(f"  {etapa:<20} {n:>12,}")
    descartadas = contagem["cadernos aceitos"] - contagem["vetor de 45 válido"]
    if descartadas:
        print(f"  ATENÇÃO: {descartadas:,} linha(s) descartada(s) por vetor de "
              "respostas/gabarito inválido.")
    if contagem["vetor de 45 válido"] == 0:
        sair("nenhuma linha restou após os filtros.")

    # --- Montagem do arquivo final ------------------------------------------
    # Letras e acertos ficam em tipos compactos (categoria / float32) para caber
    # na memória mesmo com mais de um milhão de alunos.
    print("\nMontando o arquivo para o SPSS...")
    base = pd.concat(partes, ignore_index=True)
    cod = np.ascontiguousarray(np.concatenate(blocos_cod))
    n = len(base)
    del partes, blocos_cod
    for c in base.columns:
        if c != "TX_RESPOSTAS_MT_ORIG" and c not in colunas_num:
            base[c] = base[c].astype("category")

    letras = np.unique(cod)
    lut = np.full(256, -1, dtype=np.int8)
    lut[letras] = np.arange(len(letras), dtype=np.int8)
    categorias = [chr(k) for k in letras]

    certo = (cod == ref_cod)
    dados = {}
    for c in colunas_base:
        if c == "TX_RESPOSTAS_MT":
            dados[c] = np.char.decode(cod.view(f"S{N_ITENS}").ravel(), "ascii").astype(object)
        elif c == "TX_GABARITO_MT":
            dados[c] = np.full(n, ref_gab, dtype=object)
        else:
            dados[c] = base[c]
    for j in range(N_ITENS):
        dados[f"RMT_{j + 1}"] = pd.Categorical.from_codes(lut[cod[:, j]], categories=categorias)
    for j in range(N_ITENS):
        dados[f"GMT_{j + 1}"] = pd.Categorical.from_codes(np.zeros(n, dtype=np.int8),
                                                          categories=[ref_gab[j]])
    for j in range(N_ITENS):
        col = certo[:, j].astype(np.float32)
        if anulados[j]:
            col[:] = np.nan
        elif args.branco_missing:
            col[cod[:, j] == ord(".")] = np.nan
        dados[f"ACERTO_RMT_{j + 1}"] = col
    dados["TX_RESPOSTAS_MT_ORIG"] = base["TX_RESPOSTAS_MT_ORIG"]

    # --- Conferência dos dados montados --------------------------------------
    # Depois de reordenar, o mesmo item tem que ter proporção de acerto parecida
    # em todos os cadernos, e o escore bruto tem que acompanhar a nota TRI.
    validos = ~anulados
    provas_num = base["CO_PROVA_MT"].to_numpy()
    presentes = [c for c in CADERNOS if (provas_num == int(c)).any()]
    escore = certo[:, validos].sum(axis=1)
    nota = pd.to_numeric(base["NU_NOTA_MT"], errors="coerce").to_numpy()
    ok = ~np.isnan(nota)
    print("\nConferência:")
    if len(presentes) > 1:
        p_item = np.vstack([certo[provas_num == int(c)][:, validos].mean(axis=0)
                            for c in presentes])
        amplitude = p_item.max(axis=0) - p_item.min(axis=0)
        print(f"  proporção de acerto por item, diferença entre cadernos: "
              f"máx {amplitude.max():.3f} | média {amplitude.mean():.3f}")
    print(f"  correlação entre escore bruto e NU_NOTA_MT: {np.corrcoef(escore[ok], nota[ok])[0, 1]:.3f}")
    print(f"  alunos que deixaram os 45 itens em branco: {(cod == ord('.')).all(axis=1).sum():,}")

    del cod, certo, base
    final = pd.DataFrame(dados)
    del dados

    # --- Metadados SPSS -----------------------------------------------------
    formatos = {c: f for c, f in FORMATOS.items() if c in final.columns}
    rotulos = {c: r for c, r in ROTULOS_VARIAVEIS.items() if c in final.columns}
    valores = {c: v for c, v in ROTULOS_VALORES.items() if c in final.columns}
    valores["CO_PROVA_MT"] = {int(c): NOMES_CADERNOS[c] for c in CADERNOS}
    medidas, larguras = {}, {}

    rotulo_acerto = {0: "Errou/dupla marcação" if args.branco_missing
                        else "Errou/branco/dupla marcação",
                     1: "Acertou"}
    for j, item in enumerate(corr["itens_ref"], start=1):
        sufixo = " [ANULADO]" if anulados[j - 1] else ""
        rotulos[f"RMT_{j}"] = f"Resposta ao item {j} (CO_ITEM {item}){sufixo}"
        rotulos[f"GMT_{j}"] = f"Gabarito do item {j} (CO_ITEM {item}){sufixo}"
        rotulos[f"ACERTO_RMT_{j}"] = f"Acerto no item {j} (CO_ITEM {item}){sufixo}"
        valores[f"RMT_{j}"] = {".": "Em branco", "*": "Dupla marcação"}
        valores[f"ACERTO_RMT_{j}"] = rotulo_acerto
        formatos[f"RMT_{j}"] = formatos[f"GMT_{j}"] = "A1"
        formatos[f"ACERTO_RMT_{j}"] = "F1.0"
    for c in final.columns:
        medidas[c] = MEDIDAS.get(c, "nominal")
        if c.startswith(("RMT_", "GMT_", "ACERTO_RMT_")):
            larguras[c] = len(c) + 2

    print(f"\nGravando: {saida.resolve()}")
    escrever_sav(final, saida, args, rotulos, valores, formatos, medidas, larguras)

    print("\nAlunos por caderno de origem (CO_PROVA_MT):")
    for c, q in final["CO_PROVA_MT"].value_counts().sort_index().items():
        print(f"  {int(c)} ({NOMES_CADERNOS[str(int(c))]:<10}) {q:>10,}")
    print(f"\nArquivo gerado: {saida.resolve()}  ({saida.stat().st_size / 1e6:,.0f} MB)")
    print(f"{n:,} linhas x {final.shape[1]} colunas | {time.time() - inicio:.0f}s")


def escrever_sav(final, saida, args, rotulos, valores, formatos, medidas, larguras):
    """
    Grava o .sav. As colunas de letras vão como 'category' para economizar
    memória; se a versão instalada do pyreadstat não aceitar esse tipo, elas são
    convertidas uma a uma para texto e a gravação é refeita.
    """
    def gravar():
        pyreadstat.write_sav(
            final, str(saida),
            file_label=f"ENEM 2023 - Matemática reordenada para o caderno {CADERNO_REFERENCIA}",
            column_labels=rotulos,
            variable_value_labels=valores,
            variable_format=formatos,
            variable_measure=medidas,
            variable_display_width=larguras,
            compress=args.zsav,
            row_compress=not args.zsav,
            note=["ENEM 2023: presentes em MT, nao treineiros, concluintes 2023.",
                  f"Respostas reordenadas para o caderno {CADERNO_REFERENCIA} pelo "
                  "CO_ITEM de ITENS_PROVA_2023."],
        )

    try:
        gravar()
    except Exception as erro:
        categoricas = [c for c in final.columns
                       if isinstance(final[c].dtype, pd.CategoricalDtype)]
        if not categoricas:
            raise
        print(f"  pyreadstat recusou o tipo 'category' ({erro});"
              f" convertendo {len(categoricas)} coluna(s) para texto...")
        for c in categoricas:
            final[c] = final[c].astype(str)
        gravar()


if __name__ == "__main__":
    main()
