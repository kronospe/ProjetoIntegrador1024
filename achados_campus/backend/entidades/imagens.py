"""Tratamento de fotos enviadas: valida o conteúdo, corrige a rotação,
limita as dimensões e converte para JPEG."""
import os
from io import BytesIO

from django.core.exceptions import ValidationError
from django.core.files.base import ContentFile
from PIL import Image, ImageOps

MAX_LADO = 1280
MAX_BYTES = 5 * 1024 * 1024


def processar_foto(arquivo):
    """Recebe um arquivo enviado e devolve um ContentFile JPEG otimizado."""
    if arquivo.size > MAX_BYTES:
        raise ValidationError('A foto deve ter no máximo 5 MB.')
    try:
        img = Image.open(arquivo)
        img.load()
    except Exception:
        raise ValidationError('Arquivo inválido: envie uma imagem (JPG, PNG, WebP).')

    img = ImageOps.exif_transpose(img)
    if img.mode in ('RGBA', 'LA', 'P'):
        img = img.convert('RGBA')
        fundo = Image.new('RGB', img.size, (255, 255, 255))
        fundo.paste(img, mask=img.split()[-1])
        img = fundo
    else:
        img = img.convert('RGB')

    img.thumbnail((MAX_LADO, MAX_LADO))
    buf = BytesIO()
    img.save(buf, 'JPEG', quality=85, optimize=True)
    nome = os.path.splitext(os.path.basename(arquivo.name))[0] or 'foto'
    return ContentFile(buf.getvalue(), name=f'{nome}.jpg')
