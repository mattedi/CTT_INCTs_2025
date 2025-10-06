# INCTs_Simulador_EMI

## Descrição Geral
Este repositório contém o modelo computacional **NetLogo** desenvolvido para investigar o **Efeito Mateus Institucional (EMI)** na ciência brasileira, com foco na distribuição espacial dos **Institutos Nacionais de Ciência e Tecnologia (INCTs)** ao longo das chamadas de **2008, 2014 e 2022**.

O simulador integra elementos empíricos (dados de orçamentos do CNPq e FAPs) e fundamentos teóricos para reproduzir o padrão de concentração regional e explorar cenários de políticas públicas. Ele complementa o artigo:

> **O Efeito Mateus Institucional (EMI) na Ciência Brasileira: Uma Análise da Concentração dos INCTs por Meio de Modelagem Baseada em Agente**  
> Autores: M. Mattedi, M. Speiss, G. Auzani, A. Deschamps, A. Schneider, T. Lopes  

---

## Objetivo
O modelo busca compreender como **infraestrutura científica pré-existente**, **reputação institucional** e **redes de cooperação** reproduzem desigualdades regionais no financiamento científico.  
Também avalia a eficácia de **políticas redistributivas compensatórias** e de **coalizões inter-regionais** para reduzir o hiato entre regiões centrais (Sudeste–Sul) e periféricas (Norte, Nordeste, Centro-Oeste).

---

## Fundamentos Teóricos
O modelo combina duas tradições analíticas principais:

1. **Economias de Escala Cognitivas**  
   - Vantagem acumulativa em centros já equipados, que reduzem custos marginais de submissão.  
   - Favorece laboratórios e universidades com infraestrutura robusta.  

2. **Credibilidade Cumulativa**  
   - Instituições com histórico de desempenho captam mais recursos e reforçam reputação.  
   - Processos avaliativos tendem a validar atores já consagrados.  

Esses mecanismos geram o **Efeito Mateus Institucional (EMI)**: *“A quem tem, mais será dado”* (Mateus 25:29), sociologizado por Merton (1968).

---

## Estrutura do Modelo

- **Agentes**: grupos de pesquisa distribuídos por regiões brasileiras.  
- **Variáveis principais**:  
  - `I` → infraestrutura acumulada  
  - `T` → reputação científica (publicações, citações)  
  - `R` → recursos captados anteriormente  
  - `D` → desigualdade estrutural regional  
- **Parâmetros ajustáveis**:  
  - `φ (phi)` → peso do mérito acumulado  
  - `ψ (psi)` → intensidade de políticas compensatórias  
  - `ζ (zeta)` → bônus para coalizões assimétricas (centros consolidados + periferia)  

---

## Cenários Testados
1. **EMI Pleno (φ=1, ψ=0)** → concentração máxima, dominância do eixo Sudeste–Sul.  
2. **EMI Bloqueado (φ=0, ψ=1)** → distribuição redistributiva total, mérito irrelevante.  
3. **EMI Balanceado (0 < φ < 1, 0 < ψ < 1)** → trade-off entre mérito histórico e compensação.  
4. **Coalizões (ζ > 0)** → incentivos a parcerias inter-regionais ampliam o ganho periférico.  

---

## Uso do Simulador

### Requisitos
- **NetLogo 6.3.0 ou superior**  
- Sistema operacional: Windows, Linux ou macOS  

### Passos
1. Baixe ou clone este repositório.  
2. Abra o arquivo [`INCTs_Simulador_EMI.nlogo`](INCTs_Simulador_EMI.nlogo) no NetLogo.  
3. Configure os parâmetros (`φ`, `ψ`, `ζ`) através dos *sliders* da interface.  
4. Clique em **Setup** para inicializar e depois em **Go** para rodar a simulação.  
5. Observe os gráficos:  
   - **Índice de Gini** da distribuição de recursos.  
   - **Participação regional** (N, NE, CO, SE, S).  
   - **Convergência regional** ao longo do tempo.  
6. Use **BehaviorSpace** para replicações estatísticas e análise de sensibilidade.  

---

## Principais Resultados
- A concentração histórica Sudeste–Sul se reproduz em cenários meritocráticos puros.  
- Políticas compensatórias modestas produzem apenas **ganhos marginais**.  
- Apenas quando **ψ ≥ 0,7** há redução substantiva das desigualdades regionais.  
- O **bônus de coalizão (ζ)** potencializa a participação periférica, mesmo quando o mérito ainda pesa.  
- O modelo sugere que **co-lideranças obrigatórias inter-regionais** e **matching-funds inversos ao PIB estadual** seriam mais eficazes para romper o padrão histórico.  

---

## Estrutura do Repositório

```
INCTS_SIMU_V6.nlogo
Base de dados/
   ├─ CTT_INCT_VOSviewer_template.xlsx
   ├─ Grupos de Pesquisa - Informações por Pesquisador do Edital.xlsx
   ├─ Orçamento das FAPs de todos os anos (2008, 2014, 2022, 2024).xlsx
   └─ Artigos/
         ├─ Analise_Empirica_Top20.xlsx
         ├─ Chave_1_WOS.xls
         ├─ Chave_2_WOS.xls
         ├─ Chave_3_WOS.xls
         ├─ Chave_4_WOS.xls
         ├─ Chave_5_WOS.xls
         ├─ Chave_6_WOS.xls
         ├─ Chave_7_WOS.xls
         ├─ Chave_8_WOS.xls
         ├─ Chaves_Consolidadas_SCO.xlsx
         ├─ Chaves_Consolidadas_WOS.xlsx
         ├─ CTT_INCT_VOSviewer_template.xlsx
         ├─ Quadro_Analise_Interna_Artigos.xlsx
         ├─ Resumo_Parametrico_Top20.xlsx
         ├─ SCOPUS_1_csv.csv
         ├─ SCOPUS_2_csv.csv
         ├─ SCOPUS_3_csv.csv
         ├─ SCOPUS_6_csv.csv
         ├─ SCOPUS_7_csv.csv
         ├─ SCOPUS_8_csv.csv
         ├─ Top20_Artigos_Mais_Citados_Atuais_pesquisa.xlsx
         └─ WOS_SCO_Consolidado.xlsx
Chamadas e Resultados INCTs/
   ├─ Chamada_2008.pdf
   ├─ Chamada_2014.pdf
   ├─ Chamada_2022.pdf
   └─ ResultadoFinalAprovados.pdf
```

### Descrição dos Arquivos e Pastas

- **INCTS_SIMU_V6.nlogo**: Modelo computacional desenvolvido em NetLogo para simular o Efeito Mateus Institucional (EMI) no contexto dos INCTs do campo da ciência brasileira. Contém toda a lógica, interface e parâmetros do simulador.

- **Base de dados/**: Pasta com arquivos de dados empíricos utilizados no desenvolvimento do artigo:
   - **Grupos de Pesquisa - Informações por Pesquisador do Edital.xlsx**: Informações por Pesquisador presente na relação de resultado do Edital: Dados detalhados sobre pesquisadores participantes das chamadas dos INCTs e os grupos de pesquisa coordenados por estes e dos quais eram apenas colaboradores.
   - **Orçamento das FAPs de todos os anos (2008, 2014, 2022, 2024).xlsx**: OPlanilha com os valores de orçamento das FAPs (Fundações de Amparo à Pesquisa) em diferentes anos (principalmente nos que correspondem às datas dos editais), usada para parametrizar cenários de financiamento.
   - **Artigos/**: Conjunto de arquivos de apoio à análise bibliométrica e empírica do artigo:
      - **Analise_Empirica_Top20.xlsx**: Análise dos 20 artigos mais citados.
      - **Chave_1_WOS.xls** a **Chave_8_WOS.xls**: Planilhas com dados extraídos da Web of Science para diferentes estratégias de busca.
      - **Chaves_Consolidadas_SCO.xlsx** / **Chaves_Consolidadas_WOS.xlsx**: Consolidação das buscas em SCOPUS e Web of Science.
      - **CTT_INCT_VOSviewer_template.xlsx**: Template utilizado para análise de redes de colaboração científica via VOSviewer, presentes nos trabalhos que serviram de base à escrita do artigo.
      - **Quadro_Analise_Interna_Artigos.xlsx**: Quadro comparativo interno dos artigos analisados.
      - **Resumo_Parametrico_Top20.xlsx**: Resumo paramétrico dos principais artigos.
      - **SCOPUS_1_csv.csv** a **SCOPUS_8_csv.csv**: Dados extraídos da base SCOPUS para diferentes estratégias de busca.
      - **Top20_Artigos_Mais_Citados_Atuais_pesquisa.xlsx**: Lista dos artigos mais citados na área.
      - **WOS_SCO_Consolidado.xlsx**: Consolidação geral dos dados de SCOPUS e Web of Science.

- **Chamadas e Resultados INCTs/**: Pasta com documentos oficiais das chamadas públicas e resultados dos editais dos INCTs:
   - **Chamada_2008.pdf**: Edital da chamada de 2008 para seleção dos INCTs.
   - **Chamada_2014.pdf**: Edital da chamada de 2014 para seleção dos INCTs.
   - **Chamada_2022.pdf**: Edital da chamada de 2022 para seleção dos INCTs.
   - **ResultadoFinalAprovados.pdf**: Documento com o resultado final dos projetos aprovados nas chamadas dos INCTs. Serviu de base para seleção dos pesquisadores sintetizados a planilha **Grupos de Pesquisa - Informações por Pesquisador do Edital.xlsx**.
