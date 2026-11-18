from .models import Aluno

def aluno_context(request):
    if request.user.is_authenticated:
        aluno = Aluno.objects.filter(usuario=request.user).first()
        return {'aluno': aluno}
    return {'aluno': None}
