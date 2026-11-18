"""Chatbot por regras (mesma base de conhecimento do site original).

Usa rapidfuzz no lugar do fuzzywuzzy: mesma ideia (partial_ratio de 0 a 100),
mais rápido e sem dependências extras.
"""
from rapidfuzz import fuzz

LIMIAR = 55

SUGESTOES = [
    'Como cadastrar um item?',
    'Como reivindicar um item?',
    'Quais os status do item?',
    'Como editar meu perfil?',
]

BASE_CONHECIMENTO = [
    {
        'perguntas': [
            'como cadastrar um item', 'quero cadastrar um item',
            'como registrar um item encontrado', 'como adicionar um item',
            'cadastrar item novo',
        ],
        'resposta': '📝 Para cadastrar um item, toque no botão "+" na tela de itens. Preencha o nome, descrição, local, data e uma foto (opcional). Após salvar, o item ficará visível para todos os usuários.',
    },
    {
        'perguntas': [
            'como reivindicar um item', 'quero reivindicar um item',
            'como pegar um item perdido', 'como solicitar devolução',
            'o item é meu como faço',
        ],
        'resposta': '🙋 Para reivindicar um item, abra a página do item e toque em "Reivindicar". Você precisará descrever uma prova de que o item é seu. Quem cadastrou o item poderá aprovar ou recusar.',
    },
    {
        'perguntas': [
            'perdi um item', 'como achar meu item perdido',
            'como buscar item perdido', 'procurar item no campus',
            'sumiço de item',
        ],
        'resposta': '🔍 Acesse a lista de itens e use a busca e os filtros por nome, local e situação. Se encontrar o seu item, toque em "Reivindicar" para solicitar a devolução.',
    },
    {
        'perguntas': [
            'encontrei um item', 'achei um objeto no campus',
            'quero devolver item encontrado', 'como reportar item achado',
        ],
        'resposta': '✅ Que ótimo! Toque em "+" e selecione a situação como "Encontrado". Descreva o item e o local onde foi achado para que o dono possa identificá-lo.',
    },
    {
        'perguntas': [
            'quais os status do item', 'o que significa ativo',
            'o que significa reivindicado', 'o que significa entregue',
            'situação do item',
        ],
        'resposta': '📊 Os itens possuem 3 status:\n• Ativo: disponível, aguardando o dono\n• Reivindicado: alguém solicitou o item\n• Entregue: item devolvido ao dono',
    },
    {
        'perguntas': [
            'como aprovar reivindicação', 'como confirmar entrega',
            'como recusar reivindicação', 'aprovar ou recusar pedido',
        ],
        'resposta': '✔️ Quem cadastrou o item pode aprovar ou recusar uma reivindicação. Abra o item e analise a prova enviada pelo requerente antes de decidir.',
    },
    {
        'perguntas': [
            'como criar uma conta', 'como me cadastrar no app',
            'como fazer login', 'esqueci minha senha', 'como entrar no sistema',
        ],
        'resposta': '👤 Para criar uma conta, toque em "Criar conta" na tela de login. Use seu e-mail e uma senha com pelo menos 8 caracteres. Para entrar, use o e-mail e a senha cadastrados.',
    },
    {
        'perguntas': [
            'como editar meu perfil', 'como mudar meu avatar',
            'como atualizar meus dados', 'onde fica meu perfil',
            'como alterar meu nome',
        ],
        'resposta': '⚙️ Para editar seu perfil, abra a aba "Perfil". Lá você pode alterar nome, e-mail, telefone, matrícula, curso, bio e escolher um avatar emoji.',
    },
    {
        'perguntas': [
            'como editar um item', 'como alterar informações do item',
            'modificar item cadastrado',
        ],
        'resposta': '✏️ Você pode editar apenas os itens que cadastrou. Abra o item e toque em "Editar" para modificar as informações.',
    },
    {
        'perguntas': [
            'como excluir um item', 'como deletar um item',
            'remover item cadastrado', 'apagar item',
        ],
        'resposta': '🗑️ Você pode excluir apenas os itens que cadastrou. Abra o item e toque em "Excluir". Essa ação não pode ser desfeita.',
    },
    {
        'perguntas': [
            'olá', 'oi', 'bom dia', 'boa tarde', 'boa noite', 'hello', 'hey',
        ],
        'resposta': '👋 Olá! Sou o assistente do CampusAchados. Posso te ajudar com dúvidas sobre cadastrar itens, reivindicar, editar perfil e muito mais. O que você precisa?',
    },
    {
        'perguntas': [
            'obrigado', 'obrigada', 'valeu', 'muito obrigado', 'agradeço',
        ],
        'resposta': '😊 De nada! Se tiver mais alguma dúvida é só perguntar!',
    },
    {
        'perguntas': [
            'como funciona o app', 'o que é o campusachados',
            'para que serve esse sistema', 'me explica o sistema',
        ],
        'resposta': '🎓 O CampusAchados é um sistema para registrar e encontrar itens perdidos no campus. Você pode cadastrar itens que encontrou, buscar itens que perdeu e reivindicar a devolução.',
    },
]

NAO_ENTENDI = (
    '🤔 Não entendi bem sua dúvida. Tente perguntar sobre: cadastrar item, '
    'reivindicar, status, perfil, login ou como funciona o app.'
)


def encontrar_resposta(mensagem: str) -> str:
    mensagem = (mensagem or '').strip().lower()
    melhor_score = 0
    melhor_resposta = None

    for entrada in BASE_CONHECIMENTO:
        for pergunta in entrada['perguntas']:
            score = fuzz.partial_ratio(mensagem, pergunta)
            if score > melhor_score:
                melhor_score = score
                melhor_resposta = entrada['resposta']

    if melhor_resposta and melhor_score >= LIMIAR:
        return melhor_resposta
    return NAO_ENTENDI
