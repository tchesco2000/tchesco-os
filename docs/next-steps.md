# Próximos Passos — Começando Amanhã

Este documento é o "guia do dia 1" para sair da documentação e entrar no desenvolvimento efetivo.

## O que já está pronto

- Decisões arquiteturais definidas
- Documentação completa do projeto
- Roadmap com 11 fases mapeadas
- Lista de pacotes especificada
- Estratégia multi-idioma documentada
- Checklist de testes preparado

## Ordem de execução — Dia 1 (amanhã)

### Manhã: Preparação (2 horas)

1. **Ler toda a documentação** criada (30 min)
   - Entender as decisões tomadas
   - Marcar dúvidas
2. **Instalar VirtualBox** no Windows (15 min)
3. **Baixar ISO Kubuntu 26.04 LTS** (30 min dependendo da internet)
4. **Criar VM** com configurações recomendadas (10 min)
5. **Começar instalação** Kubuntu na VM (20 min)

### Tarde: Setup do repositório (1 hora)

1. **Configurar Git no WSL** (15 min)
2. **Criar repositório tchesco-os no GitHub** (5 min)
3. **Clonar no WSL** (5 min)
4. **Copiar documentação** gerada pro repositório (10 min)
5. **Criar estrutura de pastas** (5 min)
6. **Primeiro commit e push** (10 min)
7. **Testar Claude Code** no projeto (10 min)

### Tarde/Noite: Fase 1 completa (30 min)

1. **Completar instalação do Kubuntu na VM**
2. **Fazer primeiro boot no desktop KDE**
3. **Instalar Guest Additions do VirtualBox**
4. **Criar snapshot "kubuntu-limpo"** (ponto de restauração)
5. **Celebrar!** Primeira etapa concreta completa.

## Ordem de execução — Dia 2

### Fase 2: Script base v0.1 (2-3 horas)

Usar Claude Code para:

1. Criar `scripts/tchesco-install.sh` (orquestrador)
2. Criar `scripts/modules/01-base.sh`
3. Testar na VM
4. Ajustar
5. Commit e push

## Ordem de execução — Dias seguintes

Seguir o `roadmap.md`:
- Dia 3: Fase 3 (tema macOS)
- Dia 4: Fase 3.5 (i18n)
- Dia 5: Fase 4 (dev)
- Dia 6: Fase 5 (jogos)
- Dia 7: Fase 6 (office)
- Dia 8: Fase 7 (Wine)
- Dia 9-10: Fase 8 (consolidação)
- Dia 11: Fase 9 (identidade)
- Dia 12-13: Fase 10 (ISO)
- Dia 14: Fase 11 (distribuição)

**Total estimado:** 2-3 semanas de noites e fins de semana.

## Dicas importantes

### Usar snapshots religiosamente

Cada vez que for testar algo na VM:
1. Criar snapshot antes
2. Testar
3. Se deu errado: voltar pro snapshot
4. Se deu certo: continuar e criar novo snapshot

Isso economiza horas de retrabalho.

### Commits frequentes

Regra de ouro:
- A cada módulo funcionando: commit
- A cada bug corrigido: commit
- A cada fim de dia: push no GitHub

Nunca trabalhar mais de 2 horas sem commitar.

### Documentar enquanto codifica

- Comentários nos scripts explicando o porquê, não só o quê
- Atualizar `packages.md` se adicionar/remover pacote
- Atualizar `roadmap.md` conforme avança

### Testar em etapas pequenas

- Não escrever 500 linhas de script e testar tudo junto
- Escrever 50 linhas, rodar na VM, validar
- Só depois partir pras próximas 50 linhas

### Pedir ajuda ao Claude Code

Claude Code pode:
- Gerar trechos de script
- Revisar bugs em scripts bash
- Sugerir melhorias de arquitetura
- Gerar documentação automaticamente
- Explicar comandos desconhecidos

Mas **você** testa, **você** valida, **você** decide o que vai pro commit.

## Quando pedir ajuda nesta conversa

Volte aqui quando:
- Tiver dúvida conceitual (qual caminho escolher?)
- Tiver bug estranho que Claude Code não resolve
- Quiser revisar decisões tomadas
- Estiver travado em alguma etapa
- Quiser validar se está no caminho certo

## Metas realistas

- **Semana 1:** Ambiente pronto + Fases 1-3 completas (base + tema)
- **Semana 2:** Fases 4-7 (os 3 pilares + Wine)
- **Semana 3:** Fases 8-11 (consolidação + ISO + distribuição)

Se atrasar, tudo bem. Projeto pessoal é maratona, não corrida. O importante é não parar.

## Sinal de que algo deu errado

Se depois de 2 semanas você:
- Não conseguiu fazer a VM bootar
- Está preso numa mesma fase
- O script quebra sistema inteiro repetidamente

Volta aqui pra gente replanejar. Às vezes é melhor simplificar do que insistir numa abordagem que não tá dando certo.

## Motivação final

Construir uma distro Linux é atividade que **une conhecimento técnico profundo** com **criatividade de design**. Poucas pessoas fazem isso na vida. Tchesco OS vai existir no mundo porque você decidiu criar.

Quando seus amigos instalarem e usarem, vão falar:

> "Fui, fiz meu próprio sistema operacional."

Isso é foda. Vamos.
