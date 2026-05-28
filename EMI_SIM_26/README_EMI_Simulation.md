# EMI Simulation — Modelo Baseado em Agentes para o Efeito Mateus Institucional

## 1. Visão geral

Esta aplicação implementa uma simulação computacional do **Efeito Mateus Institucional (EMI)** aplicado à concentração científica no Brasil. O modelo representa universidades ou grupos de pesquisa como agentes que competem por acesso a recursos científicos em função de infraestrutura, reputação, histórico de financiamento e desigualdade regional.

O notebook combina dois níveis de implementação:

1. **Motor EMI próprio**, responsável pela dinâmica matemática da simulação.
2. **Camada Mesa**, responsável por organizar os agentes em uma estrutura de modelagem baseada em agentes e permitir animação visual da evolução do sistema.

A aplicação foi preparada para execução em **Jupyter Notebook** ou **Google Colab**.

---

## 2. Objetivo da aplicação

O objetivo principal é simular como mecanismos cumulativos de vantagem institucional podem reforçar a concentração regional de recursos científicos.

A simulação permite observar:

- evolução do coeficiente de Gini;
- participação regional no acesso aos recursos;
- diferença entre cenários concentradores e compensatórios;
- efeito de políticas públicas parametrizadas;
- impacto de choque fiscal;
- dinâmica visual dos agentes ao longo dos ticks da simulação.

---

## 3. Estrutura conceitual do modelo

O modelo trabalha com três mecanismos principais do Efeito Mateus Institucional:

| Loop | Nome | Função no modelo |
|---|---|---|
| EMI-I | Infraestrutura | Recursos recebidos aumentam a infraestrutura futura do agente |
| EMI-T | Reputação | Recursos recebidos elevam reputação, qualificação ou visibilidade científica |
| EMI-R | Recursos históricos | Histórico de financiamento aumenta a probabilidade de novo acesso |

A lógica central é cumulativa: agentes que começam com maior infraestrutura, reputação e histórico de recursos tendem a receber mais recursos, o que reforça suas vantagens futuras.

---

## 4. Variáveis dos agentes

Cada agente representa uma instituição ou grupo de pesquisa.

| Variável | Significado |
|---|---|
| `I` | infraestrutura científica |
| `T` | reputação, qualificação ou capital científico |
| `R` | recursos históricos acumulados |
| `D` | penalidade associada à desigualdade regional |
| `acesso` | pontuação de acesso a recursos no tick atual |
| `visibilidade` | visibilidade científica calculada a partir de infraestrutura e reputação |
| `recursos_recebidos` | parcela de recursos distribuída ao agente |

Os agentes são inicializados a partir de uma lista de universidades brasileiras, distribuídas pelas regiões Norte, Nordeste, Centro-Oeste, Sul e Sudeste.

---

## 5. Equação de acesso

A aplicação calcula o acesso de cada agente aos recursos por meio da seguinte lógica:

```text
A_i(t) = φ · [I_i + T_i + R_i] · (1 - D_i) + ψ · PC(t)
```

Onde:

| Parâmetro | Significado |
|---|---|
| `A_i(t)` | acesso do agente `i` no tempo `t` |
| `φ` | peso do mérito acumulado ou vantagem institucional |
| `ψ` | peso da política compensatória |
| `I_i` | infraestrutura do agente |
| `T_i` | reputação ou qualificação |
| `R_i` | recursos históricos |
| `D_i` | desigualdade regional |
| `PC(t)` | componente de política compensatória |

Quando `φ` é alto, o sistema tende a reproduzir vantagens acumuladas. Quando `ψ` é alto, o modelo simula maior intervenção compensatória.

---

## 6. Motor principal da simulação

A classe central do modelo é:

```python
EMIEngine
```

Ela executa os seguintes procedimentos:

1. calcula o acesso de cada agente;
2. distribui recursos proporcionalmente ao acesso;
3. atualiza infraestrutura, reputação e recursos históricos;
4. calcula a visibilidade científica;
5. registra métricas agregadas;
6. repete o processo por vários ticks.

A cada tick, os agentes são atualizados segundo os três loops EMI:

```text
I(t+1) = I(t) + γI · R - δI · I(t)
T(t+1) = T(t) + γT · ln(1+R) - δT · T(t)
R(t+1) = R(t) + incremento associado aos recursos recebidos
```

---

## 7. Métricas produzidas

A aplicação calcula e visualiza várias métricas.

| Métrica | Função |
|---|---|
| `gini` | mede concentração/desigualdade do acesso |
| `shares` | participação percentual de cada região |
| `SE_N` | razão entre Sudeste e Norte |
| `emi_i` | média de infraestrutura |
| `emi_t` | média de reputação |
| `emi_r` | média de recursos históricos |
| `conv` | variação do Gini entre ticks, usada como indicador de convergência |

---

## 8. Principais blocos do notebook

O notebook está organizado em blocos funcionais.

| Seção | Conteúdo |
|---|---|
| 1 | Instalação de dependências |
| 2 | Definição do motor EMI |
| 3 | Parâmetros calibrados e agentes padrão |
| 4 | Simulações básicas |
| 5 | Isolamento dos três loops EMI |
| 6 | Cenários clássicos |
| 7 | Varredura de política pública `ψ × ζ` |
| 8 | Cenários de choque fiscal |
| 9 | Matching funds |
| 10 | Evolução temporal |
| 11 | API REST opcional |
| 12 | Mesa + animação do EMI |

---

## 9. Célula 12 — Mesa + animação

A célula 12 acrescenta uma camada de simulação baseada na biblioteca **Mesa**.

Essa célula cria:

```python
EMIInstitutionAgent
EMIMesaModel
rodar_mesa_emi()
animar_mesa_emi()
```

### 9.1. Função da camada Mesa

A camada Mesa não substitui o motor EMI. Ela encapsula a lógica do modelo em uma estrutura de agentes, permitindo:

- representar cada instituição como agente Mesa;
- executar ticks de simulação;
- registrar histórico dos agentes;
- produzir animação visual;
- observar a evolução regional do sistema.

### 9.2. Funcionamento da animação

A animação apresenta dois painéis principais:

| Painel | Conteúdo |
|---|---|
| Esquerdo | agentes posicionados por região, com tamanho associado ao acesso ou recursos |
| Direito | evolução temporal do coeficiente de Gini |

A animação mostra a transformação do sistema ao longo dos ticks. Agentes mais favorecidos tendem a aumentar sua posição relativa no acesso aos recursos. Cenários com maior política compensatória tendem a reduzir a concentração.

### 9.3. Saída da animação

Ao executar a célula 12, o notebook deve:

1. rodar a simulação Mesa;
2. gerar a animação em HTML;
3. exibir a animação abaixo da célula;
4. salvar o arquivo:

```text
emi_mesa_animacao.html
```

Esse arquivo pode ser aberto em navegador, desde que esteja disponível no ambiente de execução.

---

## 10. Como executar no Google Colab

1. Abra o arquivo `.ipynb` no Google Colab.
2. Execute as células em ordem.
3. Aguarde a instalação das dependências.
4. Execute as células de definição do motor EMI.
5. Execute as simulações desejadas.
6. Para visualizar a animação, execute a **Célula 12 — Mesa + Animação do EMI**.
7. A animação aparecerá abaixo da célula.

Caso a animação não apareça automaticamente, verifique:

- se a célula 12 foi executada;
- se `matplotlib` e `IPython.display` foram carregados;
- se o ambiente bloqueou saída HTML;
- se o arquivo `emi_mesa_animacao.html` foi gerado.

---

## 11. Dependências

A aplicação utiliza:

```text
numpy
pandas
matplotlib
scipy
mesa
IPython
```

No Colab, as dependências principais podem ser instaladas automaticamente com:

```python
!pip install numpy scipy matplotlib pandas mesa -q
```

A API opcional utiliza:

```text
fastapi
uvicorn
pyngrok
pydantic
```

---

## 12. Interpretação dos cenários

A aplicação permite comparar diferentes regimes institucionais.

| Cenário | Interpretação |
|---|---|
| EMI pleno | máxima reprodução de vantagens acumuladas |
| EMI balanceado | combinação entre mérito acumulado e política compensatória |
| EMI bloqueado | acesso totalmente determinado por componente compensatório |
| Coalizão regional | bônus para regiões periféricas |
| Choque fiscal | redução de recursos disponíveis a partir de determinado tick |
| Política dinâmica | aumento progressivo do componente compensatório |

---

## 13. Parâmetros principais

| Parâmetro | Função |
|---|---|
| `phi` | peso da vantagem institucional acumulada |
| `psi` | peso da política compensatória |
| `gamma_i` | taxa de conversão de recursos em infraestrutura |
| `delta_i` | taxa de depreciação da infraestrutura |
| `gamma_t` | taxa de conversão de recursos em reputação |
| `delta_t` | taxa de depreciação da reputação |
| `eta_1` | peso da infraestrutura na visibilidade |
| `eta_2` | peso da reputação na visibilidade |
| `zeta` | bônus de coalizão para regiões periféricas |
| `pc` | intensidade da política compensatória |

---

## 14. Resultados esperados

Em geral, espera-se observar:

1. aumento ou manutenção da concentração quando `phi` é alto;
2. redução do Gini quando `psi` aumenta;
3. maior participação relativa de regiões periféricas quando `zeta` é elevado;
4. manutenção da vantagem do Sudeste em cenários de EMI pleno;
5. redução da razão Sudeste/Norte em cenários compensatórios;
6. sensibilidade do sistema a choques fiscais e políticas dinâmicas.

---

## 15. Limitações

O modelo é uma simulação exploratória. Ele não deve ser interpretado como previsão direta da distribuição real dos recursos científicos.

As principais limitações são:

- valores iniciais simplificados para os agentes;
- ausência de dados empíricos completos por instituição;
- dinâmica regional agregada;
- ausência de rede explícita de cooperação científica;
- representação simplificada das políticas públicas;
- sensibilidade aos parâmetros escolhidos.

---

## 16. Possíveis extensões

A aplicação pode ser expandida com:

- dados empíricos reais de financiamento;
- rede de colaboração entre instituições;
- espacialização geográfica;
- integração com mapas;
- calibração estatística dos parâmetros;
- interface interativa com sliders;
- exportação automática de resultados;
- comparação entre chamadas públicas reais;
- uso de Mesa/Solara para interface web interativa.

---

## 17. Síntese operacional

| Componente | Papel na aplicação |
|---|---|
| `Agent` | representa a instituição no motor EMI original |
| `EMIEngine` | executa a dinâmica matemática do modelo |
| `AGENTES` | lista inicial de instituições simuladas |
| `PARAMS` | parâmetros calibrados do modelo |
| `run()` | executa uma simulação simples |
| `run_n()` | executa múltiplas réplicas |
| `EMIInstitutionAgent` | agente da camada Mesa |
| `EMIMesaModel` | modelo Mesa que organiza os agentes |
| `animar_mesa_emi()` | gera a animação |
| `emi_mesa_animacao.html` | saída visual exportada da animação |

---

## 18. Finalidade acadêmica

A aplicação foi construída para apoiar análise, ensino e experimentação sobre concentração científica, política pública de ciência e tecnologia e modelagem baseada em agentes.

Ela permite discutir, de modo operacional, como desigualdades institucionais podem ser reproduzidas por mecanismos aparentemente meritocráticos e como políticas compensatórias podem alterar a trajetória agregada do sistema.
