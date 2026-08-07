import sys
import os
import customtkinter as ctk

# Asegurar importaciones relativas
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from config import (
    COLOR_BG_MAIN, COLOR_BG_CARD, COLOR_PRIMARY, COLOR_PRIMARY_HOVER,
    COLOR_ACCENT, COLOR_TEXT_PRIMARY, COLOR_TEXT_SECONDARY, COLOR_BORDER,
    COMPANY_NAME, COMPANY_SLOGAN
)
from views.components import HeaderFrame
from views.login_view import LoginFrame
from views.dashboard_view import DashboardView
from views.inventory_view import InventoryView
from views.suppliers_view import SuppliersView
from views.clients_view import ClientsView
from views.quotes_view import QuotesView
from views.expenses_view import ExpensesView
from views.payroll_view import PayrollView
from views.reports_view import ReportsView
from views.users_view import UsersView
from models.models import AuditLogModel

class InegoApp(ctk.CTk):
    """ Aplicación Principal ERP / CRM Inego Industrias Desktop (Ventana Única) """
    def __init__(self):
        super().__init__()
        self.current_user = None

        # Configuración de Ventana Principal
        self.title(f"{COMPANY_NAME} - Sistema Integrado de Gestión")
        self.geometry("1280x760")
        self.minsize(1100, 680)

        # Configuración de Apariencia CustomTkinter
        ctk.set_appearance_mode("Dark")
        ctk.set_default_color_theme("blue")
        self.configure(fg_color=COLOR_BG_MAIN)

        # Contenedores principales
        self.login_frame = None
        self.header = None
        self.body_container = None
        self.sidebar = None
        self.main_content = None

        self.views = {}
        self.sidebar_buttons = {}

        # Mostrar pantalla de Login al iniciar
        self.show_login_screen()

    def show_login_screen(self):
        # Ocultar o limpiar interfaz si existía
        if self.header:
            self.header.pack_forget()
        if self.body_container:
            self.body_container.pack_forget()

        self.login_frame = LoginFrame(self, on_login_success=self.handle_login_success)
        self.login_frame.pack(fill="both", expand=True)

    def handle_login_success(self, user):
        self.current_user = user
        if self.login_frame:
            self.login_frame.pack_forget()
            self.login_frame.destroy()
            self.login_frame = None

        self.build_main_ui()

    def build_main_ui(self):
        # 1. Header Superior Corporativo
        if not self.header:
            self.header = HeaderFrame(self, title="PANEL DE CONTROL GENERAL")
        self.header.pack(fill="x", side="top")
        self.header.set_user_info(self.current_user['nombre_completo'], self.current_user['rol'])

        # Contenedor Cuerpo (Sidebar + Contenido Principal)
        if not self.body_container:
            self.body_container = ctk.CTkFrame(self, fg_color="transparent")
        self.body_container.pack(fill="both", expand=True)

        # 2. Sidebar Lateral Navegación
        if not self.sidebar:
            self.sidebar = ctk.CTkFrame(self.body_container, fg_color=COLOR_BG_CARD, width=230, corner_radius=0)
            self.sidebar.pack(side="left", fill="y")
            self.sidebar.pack_propagate(False)
            self._build_sidebar()
        else:
            self.sidebar.pack(side="left", fill="y")

        # 3. Área Principal de Vistas
        if not self.main_content:
            self.main_content = ctk.CTkFrame(self.body_container, fg_color=COLOR_BG_MAIN, corner_radius=0)
            self.main_content.pack(side="right", fill="both", expand=True)
            self._init_views()
        else:
            self.main_content.pack(side="right", fill="both", expand=True)

        # Ir al panel principal
        self.navigate_to("dashboard")

    def _init_views(self):
        self.views["dashboard"] = DashboardView(self.main_content, navigate_callback=self.navigate_to)
        self.views["inventory"] = InventoryView(self.main_content)
        self.views["suppliers"] = SuppliersView(self.main_content)
        self.views["clients"] = ClientsView(self.main_content)
        self.views["quotes"] = QuotesView(self.main_content)
        self.views["expenses"] = ExpensesView(self.main_content)
        self.views["payroll"] = PayrollView(self.main_content)
        self.views["reports"] = ReportsView(self.main_content)
        self.views["users"] = UsersView(self.main_content, current_user=self.current_user)

    def _build_sidebar(self):
        for w in self.sidebar.winfo_children():
            w.destroy()

        ctk.CTkLabel(
            self.sidebar, text="MENÚ PRINCIPAL",
            font=ctk.CTkFont(family="Segoe UI", size=11, weight="bold"),
            text_color="#64748B"
        ).pack(anchor="w", padx=20, pady=(15, 8))

        nav_items = [
            ("dashboard", "📊 Panel Principal", "PANEL DE CONTROL Y MÉTRICAS"),
            ("inventory", "📦 Catálogo y Stock", "CONTROL DE STOCK PERMANENTE Y DROP-SHIPPING"),
            ("suppliers", "🏭 Proveedores", "PROVEEDORES GUAYAQUIL E IMPORTACIONES"),
            ("clients", "👥 Clientes (B2B/B2C)", "HISTORIAL CLIENTES Y CRÉDITOS 72 DÍAS"),
            ("quotes", "📋 Cotizaciones", "COTIZADOR MULTI-PROVEEDOR Y WHATSAPP"),
            ("expenses", "🧾 Gastos y Servicios", "CONTROL DE CAJA CHICA, AGUA Y LOGÍSTICA"),
            ("payroll", "👔 Nómina de Socios", "ROLES DE PAGO FÍSICOS ($50 + 5%)"),
            ("reports", "📈 Reportes y Gantt", "DESCARGA DE EXCEL Y GANTT GOBIERNO"),
            ("users", "🛡️ Usuarios y Bitácora", "CONTROL DE ACCESO Y AUDITORÍA DE TAREAS"),
        ]

        for route, text, title_header in nav_items:
            btn = ctk.CTkButton(
                self.sidebar, text=text,
                anchor="w", height=38, corner_radius=8,
                fg_color="transparent", hover_color="#1E293B",
                text_color=COLOR_TEXT_SECONDARY,
                font=ctk.CTkFont(family="Segoe UI", size=12),
                command=lambda r=route, t=title_header: self._on_sidebar_click(r, t)
            )
            btn.pack(fill="x", padx=12, pady=2)
            self.sidebar_buttons[route] = btn

        # Footer del Sidebar
        footer_box = ctk.CTkFrame(self.sidebar, fg_color="transparent")
        footer_box.pack(side="bottom", fill="x", padx=15, pady=15)
        
        btn_logout = ctk.CTkButton(
            footer_box, text="🔒 Cerrar Sesión", command=self._logout,
            fg_color="#1E293B", hover_color="#334155", text_color="#F8FAFC",
            height=32, corner_radius=6, font=ctk.CTkFont(size=11, weight="bold")
        )
        btn_logout.pack(fill="x", pady=(0, 10))

        ctk.CTkLabel(
            footer_box, text="Inego Industrias v1.0",
            font=ctk.CTkFont(size=10, weight="bold"), text_color=COLOR_ACCENT
        ).pack(anchor="w")

    def _on_sidebar_click(self, route, title_header):
        self.header.update_module_title(title_header)
        self.navigate_to(route)

    def navigate_to(self, route):
        for r, btn in self.sidebar_buttons.items():
            if r == route:
                btn.configure(fg_color=COLOR_PRIMARY, text_color=COLOR_TEXT_PRIMARY)
            else:
                btn.configure(fg_color="transparent", text_color=COLOR_TEXT_SECONDARY)

        for view in self.views.values():
            view.pack_forget()

        if route in self.views:
            target_view = self.views[route]
            target_view.pack(fill="both", expand=True)
            if hasattr(target_view, "refresh_data"):
                target_view.refresh_data()

    def _logout(self):
        if self.current_user:
            AuditLogModel.log(
                self.current_user['nombre_completo'],
                "Cierre de Sesión",
                "El usuario cerró sesión en el sistema"
            )
        self.current_user = None
        self.show_login_screen()


if __name__ == "__main__":
    app = InegoApp()
    app.mainloop()
