import customtkinter as ctk
from views.components import PrimaryButton, AccentButton, CardFrame, StatusChip
from config import (
    COLOR_BG_MAIN, COLOR_BG_CARD, COLOR_TEXT_PRIMARY, COLOR_TEXT_SECONDARY,
    COLOR_TEXT_MUTED, COLOR_PRIMARY, COLOR_ACCENT, COLOR_SUCCESS, COLOR_DANGER,
    COMPANY_NAME, COMPANY_LOCATION
)

class SettingsView(ctk.CTkFrame):
    """ Vista de Configuración del Sistema (Modo Claro/Oscuro y Control de Sesión) """
    def __init__(self, master, current_user=None, logout_callback=None, **kwargs):
        super().__init__(master, fg_color=COLOR_BG_MAIN, corner_radius=0, **kwargs)
        self.current_user = current_user
        self.logout_callback = logout_callback

        top_bar = ctk.CTkFrame(self, fg_color=COLOR_BG_CARD, height=60, corner_radius=0)
        top_bar.pack(fill="x", side="top")

        lbl_t = ctk.CTkLabel(
            top_bar, text="⚙️ Configuración del Sistema y Preferencias de Usuario",
            font=ctk.CTkFont(family="Segoe UI", size=16, weight="bold"),
            text_color=COLOR_TEXT_PRIMARY
        )
        lbl_t.pack(side="left", padx=20)

        self.scroll = ctk.CTkScrollableFrame(self, fg_color="transparent")
        self.scroll.pack(fill="both", expand=True, padx=22, pady=20)

        # 1. Card de Preferencias de Tema y Apariencia (Modo Claro por Defecto)
        theme_card = CardFrame(self.scroll)
        theme_card.pack(fill="x", pady=(0, 20))

        th_head = ctk.CTkFrame(theme_card, fg_color="transparent")
        th_head.pack(fill="x", padx=20, pady=(16, 6))

        th_title = ctk.CTkLabel(
            th_head, text="🎨 Apariencia y Tema Visual (Twinkle Bronze)",
            font=ctk.CTkFont(family="Segoe UI", size=14, weight="bold"),
            text_color=COLOR_TEXT_PRIMARY
        )
        th_title.pack(side="left")

        chip_mode = StatusChip(th_head, "MODO CLARO (DEFAULT)", "accent")
        chip_mode.pack(side="right")
        self.chip_mode = chip_mode

        th_desc = ctk.CTkLabel(
            theme_card,
            text="Selecciona el tema de interfaz deseado. Por defecto el sistema se inicia en Modo Claro. Puedes cambiar a Modo Oscuro en cualquier momento.",
            font=ctk.CTkFont(size=11), text_color=COLOR_TEXT_MUTED, wraplength=700, justify="left"
        )
        th_desc.pack(anchor="w", padx=20, pady=(0, 14))

        theme_btn_box = ctk.CTkFrame(theme_card, fg_color="transparent")
        theme_btn_box.pack(fill="x", padx=20, pady=(0, 18))

        self.btn_light = PrimaryButton(
            theme_btn_box, "☀️ Modo Claro (Por Defecto)",
            command=lambda: self._set_mode("Light"), width=220
        )
        self.btn_light.pack(side="left", padx=(0, 10))

        self.btn_dark = AccentButton(
            theme_btn_box, "🌙 Modo Oscuro",
            command=lambda: self._set_mode("Dark"), width=220
        )
        self.btn_dark.pack(side="left")

        # 2. Card de Control de Sesión y Perfil
        session_card = CardFrame(self.scroll)
        session_card.pack(fill="x", pady=(0, 20))

        se_head = ctk.CTkFrame(session_card, fg_color="transparent")
        se_head.pack(fill="x", padx=20, pady=(16, 6))

        se_title = ctk.CTkLabel(
            se_head, text="👤 Perfil Activo y Seguridad de Sesión",
            font=ctk.CTkFont(family="Segoe UI", size=14, weight="bold"),
            text_color=COLOR_TEXT_PRIMARY
        )
        se_title.pack(side="left")

        chip_sec = StatusChip(se_head, "SESIÓN SEGURA", "success")
        chip_sec.pack(side="right")

        user_name = self.current_user['nombre_completo'] if self.current_user else "Usuario Sistema"
        user_rol = self.current_user['rol'] if self.current_user else "Administrador"

        se_desc = ctk.CTkLabel(
            session_card,
            text=f"Usuario Activo: {user_name}\nRol Asignado: {user_rol}\nSede Operativa: {COMPANY_LOCATION}",
            font=ctk.CTkFont(size=12), text_color=COLOR_TEXT_SECONDARY, justify="left"
        )
        se_desc.pack(anchor="w", padx=20, pady=(0, 14))

        btn_logout = ctk.CTkButton(
            session_card, text="🔒 Cerrar Sesión del Sistema",
            command=self._handle_logout, fg_color=("#DC2626", "#EF4444"),
            hover_color=("#B91C1C", "#DC2626"), text_color="#FFFFFF",
            font=ctk.CTkFont(family="Segoe UI", size=12, weight="bold"),
            height=38, width=260, corner_radius=8
        )
        btn_logout.pack(anchor="w", padx=20, pady=(0, 18))

        # 3. Card de Información de Sistema
        sys_card = CardFrame(self.scroll)
        sys_card.pack(fill="x", pady=(0, 20))

        sy_title = ctk.CTkLabel(
            sys_card, text="ℹ️ Información del Sistema ERP / CRM",
            font=ctk.CTkFont(family="Segoe UI", size=14, weight="bold"),
            text_color=COLOR_TEXT_PRIMARY
        )
        sy_title.pack(anchor="w", padx=20, pady=(16, 6))

        sy_info = ctk.CTkLabel(
            sys_card,
            text=f"Plataforma: {COMPANY_NAME} Desktop v2.0 (Twinkle Edition)\nArquitectura: N-Capas Modular con Carga Diferida (Lazy Loading)\nBase de Datos: MySQL 8.0 / SQLite Dual Engine\nCopyright © 2026 {COMPANY_NAME}.",
            font=ctk.CTkFont(size=11), text_color=COLOR_TEXT_MUTED, justify="left"
        )
        sy_info.pack(anchor="w", padx=20, pady=(0, 18))

    def _set_mode(self, mode):
        ctk.set_appearance_mode(mode)
        if mode == "Light":
            self.chip_mode.configure(text="MODO CLARO (DEFAULT)")
        else:
            self.chip_mode.configure(text="MODO OSCURO")

    def _handle_logout(self):
        if self.logout_callback:
            self.logout_callback()
