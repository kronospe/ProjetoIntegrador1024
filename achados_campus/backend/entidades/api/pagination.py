from rest_framework.pagination import PageNumberPagination


class PaginaPadrao(PageNumberPagination):
    page_size = 20
    page_size_query_param = 'tamanho'
    max_page_size = 50
