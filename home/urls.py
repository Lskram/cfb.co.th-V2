from django.urls import path
from . import views  # ✅ อ้างถึง views ภายในแอป

urlpatterns = [
    path('', views.index, name='home-index'),  # ✅ เส้นทางหน้าแรก
]
