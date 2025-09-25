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

