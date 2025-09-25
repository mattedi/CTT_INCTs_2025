;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;  EMI – Efeito Mateus Institucional  (v2025-06 – DADOS POR UF + COALIZÕES)  ;;
;;  ATUALIZAÇÕES PRINCIPAIS:                                                   ;;
;;  1. Dados históricos INCT por UF (27 estados)                              ;;
;;  2. Orçamentos temporais das FAPs (séries 2008-2022)                       ;;
;;  3. Slider Coalizões Assimétricas (parâmetro ζ)                            ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

extensions [ GIS ]

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 1. VARIÁVEIS GLOBAIS                                                     ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
globals [
  ;; ── índices simbólicos das cinco regiões ────────────────────────────────
  REG-NORTE REG-NORDESTE REG-CENTRO REG-SUDESTE REG-SUL

  ;; ── parâmetros controlados por sliders / chooser ────────────────────────
  phi                             ;; peso-merito   (slider)
  psi                             ;; peso-compensacao = 1 − phi (slider)
  tempo-max                       ;; horizonte da simulação (slider)
  coeficiente-zeta               ;; NOVO: coalizões assimétricas (slider)

  ;; ── tempo e ciclos INCT ─────────────────────────────────────────────────
  ano-atual                       ;; 2008 + ticks
  ciclo-atual                     ;; 1, 2, 3 → 2008/2014/2022

  ;; ── orçamentos totais (valores dinâmicos) ───────────────────────────────
  orcamento-cnpq-total
  orcamento-faps-total

  ;; ── NOVO: dados históricos por UF (27 estados) ──────────────────────────
  incts-por-uf-2008              ;; lista de 27 elementos
  incts-por-uf-2014
  incts-por-uf-2022
  mapeamento-uf-regiao           ;; vetor UF → região (1-27 → 1-5)
  siglas-ufs                     ;; nomes para debug

  ;; ── NOVO: orçamentos históricos das FAPs (séries temporais) ─────────────
  orcamentos-faps-historicos     ;; matriz 5×15 (regiões × anos 2008-2022)

  ;; ── coeficientes de conversão / depreciação / visibilidade ──────────────
  gamma-I gamma-T
  delta-I delta-T
  eta1    eta2

  ;; ── métricas globais de desigualdade ────────────────────────────────────
  gini-atual
  convergencia-regional

  debug-inct-aprovacoes
]

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 2. BREEDS  (tipos de agentes)                                            ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
breed [cnpqs            cnpq]         ;; agência federal
breed [faps             fap ]         ;; Fundações estaduais
breed [grupos-pesquisa  grupo-pesquisa]

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 3. ATRIBUTOS INDIVIDUAIS (OWN)                                           ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
grupos-pesquisa-own [
  ;; estado interno (estoque de capital científico)
  infraestrutura
  qualificacao
  recursos-historicos

  ;; contexto regional E estadual
  regiao-grupo      ;; índice 1-5
  uf-grupo          ;; NOVO: índice 1-27 (UF específica)
  D                 ;; fator de desigualdade estrutural (0–1)

  ;; variáveis de fluxo / cálculo
  acesso-recursos
  visibilidade
  bonus-coalizao    ;; NOVO: bonificação por parcerias periféricas

  ;; entradas financeiras em cada tick
  recursos-cnpq
  recursos-fap
  recursos-total
]

cnpqs-own [
  orcamento-cnpq
  alpha-cnpq
  execucao-historica    ;; NOVO: série temporal de execução
]

faps-own [
  orcamento-fap
  regiao-fap
  beta-fap
  orcamento-historico   ;; NOVO: lista [2008, 2009, ..., 2022]
  execucao-percentual   ;; NOVO: eficiência de gasto
]

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 4. PROCEDIMENTO SETUP                                                    ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to setup
  clear-all                          ;; zera mundo, gráficos e agentes

  definir-constantes-e-dados         ;; índices, coeficientes, dados UF
  inicializar-parametros-dinamicos   ;; lê sliders e zera contadores

  pintar-mapa-brasileiro-realista    ;; colore patches (5 cores)
  criar-agentes-com-series-temporais ;; CNPq, FAPs, grupos
  ajustar-estados-iniciais           ;; efeito Mateus na largada
  calcular-metricas                  ;; Gini / convergência iniciais

  reset-ticks
end

;; Liga / desliga os rótulos das FAPs
to alternar-rótulos-fap
  let visivel? any? faps with [ label != "" ]

  ifelse visivel? [
      ask faps [ set label "" ]
  ] [
      ask faps [
        if      regiao-fap = REG-NORTE    [ set label "N"  ]
        if      regiao-fap = REG-NORDESTE [ set label "NE" ]
        if      regiao-fap = REG-CENTRO   [ set label "CO" ]
        if      regiao-fap = REG-SUDESTE  [ set label "SE" ]
        if      regiao-fap = REG-SUL      [ set label "S"  ]
      ]
  ]
end

;;────────────────────────────────────────────────────────────────────────────
;; 4.1  Constantes fixas + dados históricos por UF
;;────────────────────────────────────────────────────────────────────────────
to definir-constantes-e-dados
  ;; índices regionais
  set REG-NORTE     1
  set REG-NORDESTE  2
  set REG-CENTRO    3
  set REG-SUDESTE   4
  set REG-SUL       5

  ;; siglas das UFs (para debug e relatórios)
  set siglas-ufs [
    "RO" "AC" "AM" "RR" "PA" "AP" "TO"           ;; Norte (7)
    "MA" "PI" "CE" "RN" "PB" "PE" "AL" "SE" "BA" ;; Nordeste (9)
    "MT" "MS" "GO" "DF"                          ;; Centro-Oeste (4)
    "MG" "ES" "RJ" "SP"                          ;; Sudeste (4)
    "PR" "SC" "RS"                               ;; Sul (3)
  ]

  ;; mapeamento UF → Região (1-27 → 1-5)
  set mapeamento-uf-regiao [
    1 1 1 1 1 1 1     ;; Norte: RO AC AM RR PA AP TO
    2 2 2 2 2 2 2 2 2 ;; Nordeste: MA PI CE RN PB PE AL SE BA
    3 3 3 3           ;; Centro-Oeste: MT MS GO DF
    4 4 4 4           ;; Sudeste: MG ES RJ SP
    5 5 5             ;; Sul: PR SC RS
  ]

  ;; DADOS REAIS: INCTs aprovados por UF (baseado na análise do documento)
  ;; Valores aproximados baseados na concentração SE-S mencionada
  definir-incts-por-uf-historicos
  definir-orcamentos-faps-series-temporais

  ;; orçamentos anuais aproximados (R$ milhões)
  set orcamento-cnpq-total 2000

  ;; coeficientes de física do modelo
  set gamma-I 0.15    set gamma-T 0.10   ;; conversão $ → capital
  set delta-I 0.05    set delta-T 0.03   ;; depreciação anual
  set eta1    0.6     set eta2    0.4    ;; pesos na visibilidade
end

to definir-incts-por-uf-historicos
  ;; 2008: Total 75 INCTs, concentração SE-S (documento indica ~61/75 = 81%)
  set incts-por-uf-2008 [
    ;; Norte (7 UFs) - total ~2
    0 0 1 0 1 0 0
    ;; Nordeste (9 UFs) - total ~8
    1 0 2 1 0 2 1 0 1
    ;; Centro-Oeste (4 UFs) - total ~4
    1 0 2 1
    ;; Sudeste (4 UFs) - total ~45 (concentração FAPESP/UFRJ/UFMG)
    8 2 12 23
    ;; Sul (3 UFs) - total ~16
    5 4 7
  ]

  ;; 2014: Total 93 INCTs, ligeiro crescimento periférico
  set incts-por-uf-2014 [
    ;; Norte (7 UFs) - total ~3
    0 1 1 0 1 0 0
    ;; Nordeste (9 UFs) - total ~12
    2 1 3 1 1 2 1 0 1
    ;; Centro-Oeste (4 UFs) - total ~6
    2 1 2 1
    ;; Sudeste (4 UFs) - total ~52
    10 3 15 24
    ;; Sul (3 UFs) - total ~20
    6 5 9
  ]

  ;; 2022: Total 110 INCTs, expansão moderada
  set incts-por-uf-2022 [
    ;; Norte (7 UFs) - total ~4
    1 1 1 0 1 0 0
    ;; Nordeste (9 UFs) - total ~15
    2 1 4 2 1 3 1 0 1
    ;; Centro-Oeste (4 UFs) - total ~8
    2 2 3 1
    ;; Sudeste (4 UFs) - total ~58
    12 4 17 25
    ;; Sul (3 UFs) - total ~25
    8 6 11
  ]
end

to definir-orcamentos-faps-series-temporais
  ;; Matriz 5×15: 5 regiões × 15 anos (2008-2022)
  ;; Valores em R$ milhões, baseados na Tabela 2 do documento
  ;; Interpolação linear entre marcos conhecidos

  let norte-serie     interpolar-serie 150  200  300   ;; crescimento moderado
  let nordeste-serie  interpolar-serie 400  600  800   ;; crescimento constante
  let centro-serie    interpolar-serie 200  300  400   ;; crescimento linear
  let sudeste-serie   interpolar-serie 800 1200 1510   ;; FAPESP dominante
  let sul-serie       interpolar-serie 300  400  512   ;; crescimento Sul

  set orcamentos-faps-historicos []
  set orcamentos-faps-historicos lput norte-serie     orcamentos-faps-historicos
  set orcamentos-faps-historicos lput nordeste-serie  orcamentos-faps-historicos
  set orcamentos-faps-historicos lput centro-serie    orcamentos-faps-historicos
  set orcamentos-faps-historicos lput sudeste-serie   orcamentos-faps-historicos
  set orcamentos-faps-historicos lput sul-serie       orcamentos-faps-historicos
end

;; Interpola linearmente entre três pontos (2008, 2014, 2022)
to-report interpolar-serie [v2008 v2014 v2022]
  let serie []

  ;; 2008-2014 (6 anos)
  let delta1 (v2014 - v2008) / 6
  foreach (range 7) [ i ->
    set serie lput (v2008 + i * delta1) serie
  ]

  ;; 2015-2022 (8 anos)
  let delta2 (v2022 - v2014) / 8
  foreach (range 1 9) [ i ->
    set serie lput (v2014 + i * delta2) serie
  ]

  report serie
end

;;────────────────────────────────────────────────────────────────────────────
;; 4.2  Parâmetros lidos nos sliders / chooser
;;────────────────────────────────────────────────────────────────────────────
to inicializar-parametros-dinamicos
  set phi              peso-merito
  set psi              peso-compensacao
  set tempo-max        tempo-simulacao
  set coeficiente-zeta coalizoes-assimetricas    ;; NOVO slider

  ;; inicializar flag de debug
  set debug-inct-aprovacoes false

  set ciclo-atual 1      ;; começa no edital 2008
  set ano-atual   2008
end

;;────────────────────────────────────────────────────────────────────────────
;; 4.3  Desenho em patches – contorno aproximado do Brasil
;;────────────────────────────────────────────────────────────────────────────
to pintar-mapa-brasileiro-realista
  ask patches [ set pcolor gray ]          ;; default cinza neutro

  ;; NORTE (verde claro) – três blocos que formam a "Amazônia"
  ask patches with [
    (pxcor >= -14 and pxcor <= -4  and pycor >= 6  and pycor <= 14) or
    (pxcor >= -10 and pxcor <=  0  and pycor >= 4  and pycor <=  8) or
    (pxcor >=  -6 and pxcor <=  2  and pycor >= 2  and pycor <=  6)
  ] [ set pcolor green ]

  ;; NORDESTE (azul claro) – extensão atlântica
  ask patches with [
    (pxcor >=  0 and pxcor <= 12 and pycor >=  8 and pycor <= 14) or
    (pxcor >=  2 and pxcor <= 14 and pycor >=  4 and pycor <= 10) or
    (pxcor >=  8 and pxcor <= 16 and pycor >= -2 and pycor <=  6)
  ] [ set pcolor blue ]

  ;; CENTRO-OESTE (amarelo)
  ask patches with [
    (pxcor >= -10 and pxcor <=  2 and pycor >= -6 and pycor <= 4) or
    (pxcor >=  -6 and pxcor <=  6 and pycor >= -10 and pycor <= 0)
  ] [ set pcolor yellow ]

  ;; SUDESTE (vermelho)
  ask patches with [
    (pxcor >=  2 and pxcor <= 12 and pycor >= -6  and pycor <= 4) or
    (pxcor >=  6 and pxcor <= 16 and pycor >= -12 and pycor <= 0)
  ] [ set pcolor red ]

  ;; SUL (laranja)
  ask patches with [
    (pxcor >= -2 and pxcor <=  8 and pycor >= -16 and pycor <= -10) or
    (pxcor >=  2 and pxcor <= 12 and pycor >= -20 and pycor <= -12)
  ] [ set pcolor orange ]
end

;;────────────────────────────────────────────────────────────────────────────
;; 4.4  Criação dos três tipos de agentes COM SÉRIES TEMPORAIS
;;────────────────────────────────────────────────────────────────────────────
to criar-agentes-com-series-temporais
  criar-cnpq-com-historico
  criar-faps-com-series-temporais
  criar-grupos-pesquisa-por-uf
end

;; ── 4.4.1 CNPq – com histórico de execução
to criar-cnpq-com-historico
  create-cnpqs 1 [
    set shape "star"   set size 4   set color white
    setxy -2 -3
    set orcamento-cnpq orcamento-cnpq-total
    set alpha-cnpq 0.7

    ;; Série histórica de execução (%) - baseada em ciclos econômicos
    set execucao-historica [
      85 88 90 92 85 80 75  ;; 2008-2014: crise 2008, depois crescimento
      78 82 85 88 90 85 82 75  ;; 2015-2022: crise 2015-2016, recuperação
    ]

    set label "CNPq"
  ]
end

;; ── 4.4.2 FAPs – com orçamentos e eficiência temporal
to criar-faps-com-series-temporais
  ;; coordenadas aproximadas de capitais
  let posicoes (list
    (list -8  10)  ;; Norte
    (list  8  10)  ;; Nordeste
    (list -2   0)  ;; Centro-Oeste
    (list  8  -2)  ;; Sudeste
    (list  4 -14)  ;; Sul
  )

  let regioes (list REG-NORTE REG-NORDESTE REG-CENTRO REG-SUDESTE REG-SUL)
  let labels (list "N" "NE" "CO" "SE" "S")

  ;; criar uma FAP por região com séries temporais
  let i 0
  foreach regioes [ reg ->
    create-faps 1 [
      set regiao-fap reg
      set color white
      set shape "triangle"
      set size 2

      ;; posicionamento
      let pos item i posicoes
      setxy (item 0 pos) (item 1 pos)

      ;; SÉRIE HISTÓRICA DE ORÇAMENTOS
      set orcamento-historico item i orcamentos-faps-historicos

      ;; orçamento atual (ano 0 = 2008)
      set orcamento-fap item 0 orcamento-historico

      ;; peso inicial
      let total-atual sum [item 0 [orcamento-historico] of self] of faps
      set beta-fap orcamento-fap / (total-atual + 0.01)

      ;; eficiência de execução por região
      set execucao-percentual (ifelse-value
        (reg = REG-SUDESTE) [0.92]   ;; FAPESP alta eficiência
        (reg = REG-SUL)     [0.88]   ;; Sul boa gestão
        (reg = REG-NORDESTE)[0.85]   ;; Nordeste moderada
        (reg = REG-CENTRO)  [0.82]   ;; Centro-Oeste menor
                            [0.78])  ;; Norte limitações

      ;; label com orçamento inicial
      set label (word (item i labels) "\n$" (precision orcamento-fap 0) "M")
    ]
    set i i + 1
  ]
end

;; ── 4.4.3 Grupos de pesquisa por UF específica
to criar-grupos-pesquisa-por-uf
  create-grupos-pesquisa num-grupos [
    set shape "circle"  set size 1  set color black

    ;; sorteio ponderado da UF (baseado na distribuição real de grupos)
    sortear-uf-e-regiao

    ;; desigualdade estrutural D por UF (mais granular)
    definir-desigualdade-por-uf

    posicionar-dentro-da-regiao-colorida

    ;; capital científico inicial (distribuição normal truncada em >0)
    set infraestrutura      max (list 0.1 (random-normal 10 3))
    set qualificacao        max (list 0.1 (random-normal  8 2))
    set recursos-historicos max (list 0.1 (random-normal  5 1))

    set recursos-cnpq 0  set recursos-fap 0  set recursos-total 0
    set bonus-coalizao 0
  ]
end

to sortear-uf-e-regiao
  ;; Distribuição baseada no Gráfico 3 do documento
  ;; SP dominante, depois RJ, MG, RS, etc.
  let prob random-float 100

  if prob < 25 [ set uf-grupo 23 set regiao-grupo REG-SUDESTE ]      ;; SP
  if prob >= 25 and prob < 35 [ set uf-grupo 22 set regiao-grupo REG-SUDESTE ]  ;; RJ
  if prob >= 35 and prob < 42 [ set uf-grupo 20 set regiao-grupo REG-SUDESTE ]  ;; MG
  if prob >= 42 and prob < 47 [ set uf-grupo 27 set regiao-grupo REG-SUL ]      ;; RS
  if prob >= 47 and prob < 51 [ set uf-grupo 25 set regiao-grupo REG-SUL ]      ;; PR
  if prob >= 51 and prob < 55 [ set uf-grupo 9  set regiao-grupo REG-NORDESTE ] ;; CE
  if prob >= 55 and prob < 58 [ set uf-grupo 26 set regiao-grupo REG-SUL ]      ;; SC
  if prob >= 58 and prob < 60 [ set uf-grupo 15 set regiao-grupo REG-NORDESTE ] ;; PE
  if prob >= 60 and prob < 62 [ set uf-grupo 16 set regiao-grupo REG-NORDESTE ] ;; BA
  if prob >= 62 and prob < 64 [ set uf-grupo 18 set regiao-grupo REG-CENTRO ]   ;; GO

  ;; demais UFs com probabilidade menor
  if prob >= 64 [
    let outras-ufs [1 2 3 4 5 6 7 8 10 11 12 13 14 17 19 21 24]
    set uf-grupo one-of outras-ufs
    set regiao-grupo item (uf-grupo - 1) mapeamento-uf-regiao
  ]
end

to definir-desigualdade-por-uf
  ;; D mais granular baseado na posição da UF no ranking
  ;; Estados com melhor infraestrutura têm D menor
  if uf-grupo = 23 [ set D 0.1 ]  ;; SP - menor desigualdade
  if uf-grupo = 22 [ set D 0.15 ] ;; RJ
  if uf-grupo = 20 [ set D 0.2 ]  ;; MG
  if member? uf-grupo [25 26 27] [ set D 0.25 ] ;; Sul
  if member? uf-grupo [9 15 16] [ set D 0.45 ]  ;; CE PE BA
  if member? uf-grupo [18 19] [ set D 0.4 ]     ;; GO DF

  ;; demais estados Norte/Nordeste
  if D = 0 [ set D 0.6 + random-float 0.2 ]    ;; 0.6-0.8
end

;; posiciona cada grupo dentro dos blocos coloridos da sua região
to posicionar-dentro-da-regiao-colorida
  if regiao-grupo = REG-NORTE [
    let op random 3
    if op = 0 [ setxy (random-float 10 - 14) (random-float  8 + 6) ]
    if op = 1 [ setxy (random-float 10 - 10) (random-float  4 + 4) ]
    if op = 2 [ setxy (random-float  8  - 6) (random-float  4 + 2) ]
  ]
  if regiao-grupo = REG-NORDESTE [
    let op random 3
    if op = 0 [ setxy (random-float 12 + 0)  (random-float 6 + 8) ]
    if op = 1 [ setxy (random-float 12 + 2)  (random-float 6 + 4) ]
    if op = 2 [ setxy (random-float  8 + 8)  (random-float 8 - 2) ]
  ]
  if regiao-grupo = REG-CENTRO [
    let op random 2
    if op = 0 [ setxy (random-float 12 - 10) (random-float 10 -  6) ]
    if op = 1 [ setxy (random-float 12 -  6) (random-float 10 - 10) ]
  ]
  if regiao-grupo = REG-SUDESTE [
    let op random 2
    if op = 0 [ setxy (random-float 10 + 2)  (random-float 10 -  6) ]
    if op = 1 [ setxy (random-float 10 + 6)  (random-float 12 - 12) ]
  ]
  if regiao-grupo = REG-SUL [
    let op random 2
    if op = 0 [ setxy (random-float 10 - 2)  (random-float  6 - 16) ]
    if op = 1 [ setxy (random-float 10 + 2)  (random-float  8 - 20) ]
  ]
end

;; efeito Mateus inicial: vantagem SE, desvantagem N
to ajustar-estados-iniciais
  ask grupos-pesquisa [
    if regiao-grupo = REG-SUDESTE [
      set infraestrutura      infraestrutura      * 1.5
      set qualificacao        qualificacao        * 1.3
      set recursos-historicos recursos-historicos * 1.4 ]
    if regiao-grupo = REG-NORTE [
      set infraestrutura      infraestrutura      * 0.6
      set qualificacao        qualificacao        * 0.7
      set recursos-historicos recursos-historicos * 0.5 ]
  ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 5. LOOP PRINCIPAL                                                        ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to go
  if ticks >= tempo-max [ stop ]         ;; fim da simulação

  ;; avança calendário e aplica editais
  set ano-atual 2008 + ticks
  if member? ano-atual (list 2008 2014 2022) [
    aplicar-edital-inct-por-uf ]

  ;; lê sliders a cada tick (permite mudança on-the-fly)
  set phi              peso-merito
  set psi              peso-compensacao
  set coeficiente-zeta coalizoes-assimetricas

  ;; NOVO: atualizar orçamentos baseados no ano atual
  atualizar-orcamentos-anuais

  ;; sequência causal em seis passos (+ coalizões)
  calcular-acesso-recursos-com-coalizoes
  distribuir-recursos-cnpq
  distribuir-recursos-faps-temporais
  atualizar-estados-grupos
  calcular-visibilidade

  calcular-metricas
  atualizar-visual

  tick
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 6. FUNÇÕES DE DINÂMICA ATUALIZADAS                                       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; NOVO: Atualizar orçamentos baseados no ano atual
to atualizar-orcamentos-anuais
  let idx-ano ano-atual - 2008
  if idx-ano >= 0 and idx-ano < 15 [

    ;; atualizar CNPq
    ask cnpqs [
      if idx-ano < length execucao-historica [
        let eficiencia item idx-ano execucao-historica
        set orcamento-cnpq orcamento-cnpq-total * (eficiencia / 100)
      ]
    ]

    ;; atualizar FAPs
    ask faps [
      if idx-ano < length orcamento-historico [
        set orcamento-fap (item idx-ano orcamento-historico) * execucao-percentual
      ]
    ]

    ;; recalcular betas das FAPs
    let total-faps sum [orcamento-fap] of faps
    if total-faps > 0 [
      ask faps [
        set beta-fap orcamento-fap / total-faps
      ]
    ]
  ]
end

;; 6.1  Equação EMI COM COALIZÕES ASSIMÉTRICAS
to calcular-acesso-recursos-com-coalizoes
  ask grupos-pesquisa [
    let merito infraestrutura + qualificacao + recursos-historicos

    ;; NOVO: Calcular bonificação por coalizões assimétricas
    set bonus-coalizao calcular-bonus-coalizao-assimetrica

    ;; Equação EMI expandida com termo ζ
    set acesso-recursos (phi * merito * (1 - D)) +
                         (psi * 10) +
                         (coeficiente-zeta * bonus-coalizao)

    if acesso-recursos < 0 [ set acesso-recursos 0.1 ]
  ]
end

;; NOVO: Calcular bonificação por parcerias periféricas
to-report calcular-bonus-coalizao-assimetrica
  let bonus 0

  ;; Grupos periféricos (Norte/Nordeste) ganham bônus por parcerias
  if regiao-grupo = REG-NORTE or regiao-grupo = REG-NORDESTE [

    ;; Simular probabilidade de parceria com centros (SE/Sul)
    ;; Baseado na distância e diferença de infraestrutura
    let prob-parceria-sudeste random-float 0.4   ;; até 40% chance SE
    let prob-parceria-sul     random-float 0.25   ;; até 25% chance Sul

    if prob-parceria-sudeste > 0.3 [
      set bonus bonus + (random-float 3 + 2)      ;; bônus 2-5 pontos SE
    ]

    if prob-parceria-sul > 0.2 [
      set bonus bonus + (random-float 2 + 1)      ;; bônus 1-3 pontos Sul
    ]

    ;; Bônus adicional para UFs mais periféricas
    if member? uf-grupo [1 2 3 4 6 7] [           ;; Norte extremo
      set bonus bonus + random-float 2
    ]
  ]

  ;; Centro-Oeste recebe bônus menor
  if regiao-grupo = REG-CENTRO [
    let prob-parceria random-float 0.3
    if prob-parceria > 0.2 [
      set bonus bonus + random-float 1.5
    ]
  ]

  report bonus
end

;; 6.2  Distribuição do bolo CNPq (proporcional a A_i)
to distribuir-recursos-cnpq
  if any? cnpqs [
    let total [orcamento-cnpq] of one-of cnpqs
    let soma  sum [acesso-recursos] of grupos-pesquisa
    if soma > 0 [
      ask grupos-pesquisa [
        set recursos-cnpq (acesso-recursos / soma) * total *
                           [alpha-cnpq] of one-of cnpqs
      ]
    ]
  ]
end

;; 6.3  Distribuição regional pelas FAPs - COM ORÇAMENTOS TEMPORAIS
to distribuir-recursos-faps-temporais
  ask faps [
    let reg regiao-fap
    let G grupos-pesquisa with [regiao-grupo = reg]
    let soma sum [acesso-recursos] of G
    if soma > 0 [
      ask G [
        ;; Usa orçamento atual da FAP (já atualizado por ano)
        set recursos-fap (acesso-recursos / soma) *
                          [orcamento-fap] of myself *
                          [beta-fap] of myself
      ]
    ]
  ]
end

;; 6.4  Atualiza estoques de capital (inalterado)
to atualizar-estados-grupos
  ask grupos-pesquisa [
    set recursos-total recursos-cnpq + recursos-fap

    set infraestrutura infraestrutura +
                       (gamma-I * recursos-total) -
                       (delta-I * infraestrutura)

    set qualificacao   qualificacao   +
                       (gamma-T * ln (1 + recursos-total)) -
                       (delta-T * qualificacao)

    set recursos-historicos (0.7 * recursos-historicos) +
                             (0.3 * recursos-total)
  ]
end

;; 6.5  Visibilidade científica (função linear de I e T)
to calcular-visibilidade
  ask grupos-pesquisa [
    set visibilidade (eta1 * infraestrutura) + (eta2 * qualificacao)
  ]
end

;; 6.6  EDITAIS INCT POR UF (NOVO - dados granulares)
to aplicar-edital-inct-por-uf
  if ciclo-atual <= 3 [
    let dados-uf (ifelse-value
      (ciclo-atual = 1) [incts-por-uf-2008]
      (ciclo-atual = 2) [incts-por-uf-2014]
                        [incts-por-uf-2022])

    let bonus item (ciclo-atual - 1) (list 2.0 1.8 1.5)

    let multI (1 + bonus * 0.3)
    let multT (1 + bonus * 0.2)
    let multR (1 + bonus * 0.4)

    ;; percorre UFs 1-27
    foreach (range 1 28) [ uf-id ->
      let aprovados item (uf-id - 1) dados-uf
      let G grupos-pesquisa with [uf-grupo = uf-id]

      if any? G and aprovados > 0 [
        let n min (list aprovados count G)
        let elite max-n-of n G [infraestrutura + qualificacao + recursos-historicos]
        ask elite [
          set infraestrutura      infraestrutura      * multI
          set qualificacao        qualificacao        * multT
          set recursos-historicos recursos-historicos * multR
        ]

        ;; Debug: mostrar aprovações por UF
        if debug-inct-aprovacoes [
          let sigla item (uf-id - 1) siglas-ufs
          print (word "INCT " ano-atual ": " sigla " → " aprovados " grupos")
        ]
      ]
    ]
    set ciclo-atual ciclo-atual + 1
  ]
end

;; 6.7  Métricas de Gini e convergência regional (inalterada)
to calcular-metricas
  if any? grupos-pesquisa [
    set gini-atual calcular-gini sort [acesso-recursos] of grupos-pesquisa

    let medias []
    foreach (range 1 6) [ rid ->
      let G grupos-pesquisa with [regiao-grupo = rid]
      if any? G [ set medias lput mean [acesso-recursos] of G medias ]
    ]
    if length medias > 1 [
      set convergencia-regional variance medias ]
  ]
end

;; índice de Gini genérico
to-report calcular-gini [xs]
  let n length xs
  if n <= 1 [ report 0 ]
  let soma sum xs
  if soma = 0 [ report 0 ]
  let dif 0
  foreach xs [xi ->
    foreach xs [xj -> set dif dif + abs (xi - xj)]]
  report dif / (2 * n * soma)
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 7. VISUALIZAÇÃO ATUALIZADA                                               ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to atualizar-visual
  atualizar-cores-grupos
  atualizar-plots

  ;; NOVO: atualizar labels das FAPs com orçamentos atuais
  if any? faps with [label != ""] [
    ask faps [
      let nome (ifelse-value
        (regiao-fap = REG-NORTE)    ["N"]
        (regiao-fap = REG-NORDESTE) ["NE"]
        (regiao-fap = REG-CENTRO)   ["CO"]
        (regiao-fap = REG-SUDESTE)  ["SE"]
                                    ["S"])
      set label (word nome "\n$" (precision orcamento-fap 0) "M")
    ]
  ]
end

;; grupos coloridos por acesso + tamanho proporcional
to atualizar-cores-grupos
  if any? grupos-pesquisa [
    let maxA max [acesso-recursos] of grupos-pesquisa
    let minA min [acesso-recursos] of grupos-pesquisa
    let rangeA maxA - minA

    ask grupos-pesquisa [
      ;; cor baseada no bônus de coalizão
      if bonus-coalizao > 2 [ set color orange ]   ;; com bônus alto
      if bonus-coalizao > 0 and bonus-coalizao <= 2 [ set color yellow ] ;; bônus baixo
      if bonus-coalizao = 0 [ set color black ]    ;; sem bônus

      ;; tamanho proporcional ao acesso
      let frac (ifelse-value (rangeA = 0) [0] [(acesso-recursos - minA) / rangeA])
      set size 0.5 + (frac * 1.5)      ;; 0.5 – 2.0
    ]
  ]
end

;; plots atualizados
to atualizar-plots
  carefully [
    set-current-plot "Gini"     set-current-plot-pen "Índice"
    plot gini-atual ] []

  ;; plot Recursos por região
  carefully [
    set-current-plot "Recursos" set-current-plot-pen "SE"
    plot recursos-sudeste ] []
  carefully [
    set-current-plot "Recursos" set-current-plot-pen "S"
    plot recursos-sul ] []
  carefully [
    set-current-plot "Recursos" set-current-plot-pen "NE"
    plot recursos-nordeste ] []
  carefully [
    set-current-plot "Recursos" set-current-plot-pen "CO"
    plot recursos-centro-oeste ] []
  carefully [
    set-current-plot "Recursos" set-current-plot-pen "N"
    plot recursos-norte ] []

  ;; NOVO: plot Coalizões Assimétricas
  carefully [
    set-current-plot "Coalizões" set-current-plot-pen "Bônus Médio"
    plot mean [bonus-coalizao] of grupos-pesquisa ] []
  carefully [
    set-current-plot "Coalizões" set-current-plot-pen "Grupos Beneficiados"
    plot count grupos-pesquisa with [bonus-coalizao > 0] ] []

  ;; plot Visibilidade média
  carefully [
    set-current-plot "Visibilidade" set-current-plot-pen "Média"
    plot mean [visibilidade] of grupos-pesquisa ] []
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 8. REPORTERS ATUALIZADOS                                                 ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Resources por região (inalterados)
to-report recursos-sudeste
  let g grupos-pesquisa with [regiao-grupo = REG-SUDESTE]
  report (ifelse-value any? g [mean [recursos-total] of g] [0])
end
to-report recursos-sul
  let g grupos-pesquisa with [regiao-grupo = REG-SUL]
  report (ifelse-value any? g [mean [recursos-total] of g] [0])
end
to-report recursos-nordeste
  let g grupos-pesquisa with [regiao-grupo = REG-NORDESTE]
  report (ifelse-value any? g [mean [recursos-total] of g] [0])
end
to-report recursos-centro-oeste
  let g grupos-pesquisa with [regiao-grupo = REG-CENTRO]
  report (ifelse-value any? g [mean [recursos-total] of g] [0])
end
to-report recursos-norte
  let g grupos-pesquisa with [regiao-grupo = REG-NORTE]
  report (ifelse-value any? g [mean [recursos-total] of g] [0])
end

to-report concentracao-sudeste
  let tot sum [recursos-total] of grupos-pesquisa
  if tot = 0 [report 0]
  report 100 * (sum [recursos-total] of grupos-pesquisa with [regiao-grupo = REG-SUDESTE]) / tot
end

;; NOVOS REPORTS para análise temporal e coalizões
to-report bonus-coalizao-medio
  if any? grupos-pesquisa [
    report mean [bonus-coalizao] of grupos-pesquisa
  ]
  report 0
end

to-report grupos-com-bonus
  report count grupos-pesquisa with [bonus-coalizao > 0]
end

to-report efetividade-coalizoes
  ;; mede se coalizões reduzem desigualdade SE vs Norte
  let recursos-n recursos-norte
  let recursos-se recursos-sudeste
  if recursos-n > 0 and recursos-se > 0 [
    let razao recursos-se / recursos-n
    ;; quanto menor a razão, maior a efetividade das coalizões
    report 10 / (razao + 1)
  ]
  report 0
end

to-report orcamento-fap-atual [regiao]
  let fap-reg one-of faps with [regiao-fap = regiao]
  if fap-reg != nobody [
    report [orcamento-fap] of fap-reg
  ]
  report 0
end

to-report orcamento-cnpq-atual
  if any? cnpqs [
    report [orcamento-cnpq] of one-of cnpqs
  ]
  report 0
end

;; Estatísticas por UF (top 5)
to-report top-ufs-recursos
  let recursos-por-uf []
  foreach (range 1 28) [ uf-id ->
    let G grupos-pesquisa with [uf-grupo = uf-id]
    if any? G [
      let media-uf mean [recursos-total] of G
      let sigla item (uf-id - 1) siglas-ufs
      set recursos-por-uf lput (list sigla media-uf) recursos-por-uf
    ]
  ]

  ;; ordenar por recursos (decrescente)
  set recursos-por-uf sort-by [ [a b] -> (item 1 a) > (item 1 b) ] recursos-por-uf

  ;; retornar top 5
  let resultado []
  let n min (list 5 (length recursos-por-uf))
  foreach (range n) [ i ->
    let entrada item i recursos-por-uf
    set resultado lput (word (item 0 entrada) ": " (precision (item 1 entrada) 1) "M") resultado
  ]
  report resultado
end

to-report distribuicao-incts-por-regiao-atual
  ;; conta aprovações INCT acumuladas por região
  let resultado []
  foreach (range 1 6) [ reg ->
    let nome-reg "Desconhecida"
    if reg = REG-NORTE [ set nome-reg "Norte" ]
    if reg = REG-NORDESTE [ set nome-reg "Nordeste" ]
    if reg = REG-CENTRO [ set nome-reg "Centro-Oeste" ]
    if reg = REG-SUDESTE [ set nome-reg "Sudeste" ]
    if reg = REG-SUL [ set nome-reg "Sul" ]

    ;; grupos com alta infraestrutura = simulação de INCTs aprovados
    let G grupos-pesquisa with [regiao-grupo = reg]
    let incts-simulados 0
    if any? G [
      let elite max-n-of (count G / 10 + 1) G [infraestrutura + qualificacao]
      set incts-simulados count elite
    ]

    set resultado lput (word nome-reg ": " incts-simulados) resultado
  ]
  report resultado
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 9. PROCEDIMENTOS DEBUG E ANÁLISE                                         ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Switch para debug de aprovações INCT
to toggle-debug-inct
  set debug-inct-aprovacoes not debug-inct-aprovacoes
  print (word "Debug INCT aprovações: " debug-inct-aprovacoes)
end

to debug-coalizoes-detalhado
  print "=== ANÁLISE DETALHADA DAS COALIZÕES ASSIMÉTRICAS ==="
  print (word "Parâmetro ζ (zeta): " coeficiente-zeta)
  print (word "Grupos com bônus: " grupos-com-bonus " de " count grupos-pesquisa)
  print (word "Bônus médio: " (precision bonus-coalizao-medio 2))
  print (word "Efetividade (anti-concentração): " (precision efetividade-coalizoes 2))

  print "\n--- DISTRIBUIÇÃO DE BÔNUS POR REGIÃO ---"
  foreach (range 1 6) [ reg ->
    let nome (ifelse-value
      (reg = REG-NORTE)    ["Norte"]
      (reg = REG-NORDESTE) ["Nordeste"]
      (reg = REG-CENTRO)   ["Centro-Oeste"]
      (reg = REG-SUDESTE)  ["Sudeste"]
                           ["Sul"])
    let G grupos-pesquisa with [regiao-grupo = reg]
    if any? G [
      let media-bonus mean [bonus-coalizao] of G
      let com-bonus count G with [bonus-coalizao > 0]
      print (word nome ": " (precision media-bonus 2) " (bônus médio), "
                  com-bonus " grupos beneficiados")
    ]
  ]

  print "\n--- TOP 5 UFs POR RECURSOS ATUAIS ---"
  foreach top-ufs-recursos [ linha -> print linha ]
end

to debug-orcamentos-temporais
  ;print "=== ORÇAMENTOS ATUAIS (ANO " ano-atual ") ==="
  print (word "CNPq: R$ " (precision orcamento-cnpq-atual 0) " milhões")

  print "\n--- FAPs POR REGIÃO ---"
  ask faps [
    let nome (ifelse-value
      (regiao-fap = REG-NORTE)    ["Norte"]
      (regiao-fap = REG-NORDESTE) ["Nordeste"]
      (regiao-fap = REG-CENTRO)   ["Centro-Oeste"]
      (regiao-fap = REG-SUDESTE)  ["Sudeste"]
                                  ["Sul"])
    print (word nome ": R$ " (precision orcamento-fap 0) "M (β=" (precision beta-fap 3)
                ", exec=" (precision (execucao-percentual * 100) 1) "%)")
  ]

  let total-faps sum [orcamento-fap] of faps
  print (word "\nTotal FAPs: R$ " (precision total-faps 0) " milhões")
  print (word "Razão FAPESP/Norte: "
              (precision (orcamento-fap-atual REG-SUDESTE / orcamento-fap-atual REG-NORTE) 1))
end

to debug-incts-por-uf-detalhado
  if ciclo-atual > 3 [
    print "Todos os ciclos INCT já foram executados"
    stop
  ]

  let dados-atuais (ifelse-value
    (ciclo-atual = 1) [incts-por-uf-2008]
    (ciclo-atual = 2) [incts-por-uf-2014]
                      [incts-por-uf-2022])

  print (word "=== DISTRIBUIÇÃO INCT POR UF - CICLO " ciclo-atual " ===")

  foreach (range 27) [ i ->
    let aprovados item i dados-atuais
    if aprovados > 0 [
      let sigla item i siglas-ufs
      let regiao item i mapeamento-uf-regiao
      let nome-reg (ifelse-value
        (regiao = REG-NORTE)    ["Norte"]
        (regiao = REG-NORDESTE) ["Nordeste"]
        (regiao = REG-CENTRO)   ["Centro-Oeste"]
        (regiao = REG-SUDESTE)  ["Sudeste"]
                                ["Sul"])
      print (word sigla " (" nome-reg "): " aprovados " INCTs")
    ]
  ]
end

;; Experimento controlado: testar cenários ζ
to experimento-cenarios-zeta
  print "=== EXPERIMENTO: IMPACTO DO PARÂMETRO ζ ==="

  let zetas [0.0 0.5 1.0 1.5 2.0]
  let resultados []

  foreach zetas [ z ->
    ;; salvar estado atual
    let phi-orig phi
    let psi-orig psi
    let zeta-orig coeficiente-zeta

    ;; definir cenário
    set phi 0.7
    set psi 0.3
    set coeficiente-zeta z

    ;; simular algumas iterações
    repeat 10 [
      calcular-acesso-recursos-com-coalizoes
      calcular-metricas
    ]

    ;; registrar resultado
    let resultado (list z (precision gini-atual 3) (precision efetividade-coalizoes 2))
    set resultados lput resultado resultados

    ;; restaurar estado
    set phi phi-orig
    set psi psi-orig
    set coeficiente-zeta zeta-orig
  ]

  print "\nζ | Gini | Efetividade"
  print "---|------|------------"
  foreach resultados [ r ->
    print (word (item 0 r) " | " (item 1 r) " | " (item 2 r))
  ]
end
@#$#@#$#@
GRAPHICS-WINDOW
336
9
774
448
-1
-1
13.030303030303031
1
10
1
1
1
0
1
1
1
-16
16
-16
16
0
0
1
ticks
30.0

BUTTON
11
74
93
107
-SETUP- 
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
10
119
95
152
--- GO ---
go
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
104
73
137
223
num-grupos
num-grupos
10
300
160.0
1
1
NIL
VERTICAL

SLIDER
151
73
184
223
peso-merito
peso-merito
0
1
0.5
0.1
1
NIL
VERTICAL

SLIDER
200
74
233
224
peso-compensacao
peso-compensacao
0
1
0.5
0.1
1
NIL
VERTICAL

SLIDER
293
77
326
227
tempo-simulacao
tempo-simulacao
1
30
14.0
1
1
NIL
VERTICAL

MONITOR
781
58
836
103
 Sudest
recursos-sudeste
2
1
11

MONITOR
781
110
838
155
Norte
recursos-norte
2
1
11

MONITOR
782
162
839
207
Norde
recursos-nordeste
2
1
11

MONITOR
782
213
839
258
Centro
recursos-centro-oeste
2
1
11

MONITOR
783
265
840
310
    Sul
recursos-sul
2
1
11

PLOT
846
59
1231
179
Índice de Gini
Tempo
Gini
0.0
3.0
0.0
1.0
true
true
"" ""
PENS
"Índice" 1.0 0 -2674135 true "" "set-current-plot \"Índice de Gini\""
"Gini" 1.0 0 -13791810 true "" "set-current-plot-pen \"Gini\""
"Gini Atual" 1.0 0 -13840069 true "" "plot gini-atual"

PLOT
846
187
1231
318
INCTs Históricos por Região
Tempo
INCTs Aprovados
0.0
14.0
0.0
60.0
false
true
"" ""
PENS
"Sud" 1.0 0 -2674135 true "" "plot recursos-sudeste"
"Sul" 1.0 0 -955883 true "" "plot recursos-sul"
"Nor" 1.0 0 -13345367 true "" "plot recursos-nordeste"
"Cen" 1.0 0 -1184463 true "" "plot recursos-centro-oeste"
"Nort" 1.0 0 -13840069 true "" "plot recursos-norte"

TEXTBOX
193
34
343
56
ENTRADA
18
15.0
1

TEXTBOX
1002
27
1152
49
SAÍDA
18
64.0
1

SLIDER
246
76
279
226
peso-visibilidade
peso-visibilidade
0
1
0.0
0.1
1
NIL
VERTICAL

SLIDER
152
261
330
294
coalizoes-assimetricas
coalizoes-assimetricas
0
10
4.0
1
1
NIL
HORIZONTAL

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.4.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
