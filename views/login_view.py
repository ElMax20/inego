import sys
import customtkinter as ctk
from PIL import ImageTk
from config import (
    COLOR_BG_MAIN, COLOR_BG_CARD, COLOR_PRIMARY, COLOR_PRIMARY_HOVER,
    COLOR_ACCENT, COLOR_TEXT_PRIMARY, COLOR_TEXT_MUTED, COLOR_DANGER,
    COMPANY_NAME, COMPANY_SLOGAN
)
from utils.assets import generate_tree_of_life_image
from models.models import UserModel, AuditLogModel

class LoginFrame(ctk.CTkFrame):
    """ Frame de Autenticación e Inicio de Sesión Seguro con Límite de 3 Intentos (RF1.1) """
    def __init__(self, master, on_login_success, **kwargs):
        super().__init__(master, fg_color=COLOR_BG_MAIN, corner_radius=0, **kwargs)
        self.on_login_success = on_login_success
        self.login_attempts = 0

        # Contenedor Tarjeta Elevada Centrada
        center_container = ctk.CTkFrame(self, fg_color="transparent")
        center_container.pack(expand=True)

        card = ctk.CTkFrame(center_container, fg_color=COLOR_BG_CARD, corner_radius=16, border_width=1, border_color="#1E293B")
        card.pack(padx=30, pady=30)

        # Logo Árbol de la Vida
        pil_img = generate_tree_of_life_image(90, 90)
        self.logo_img = ctk.CTkImage(light_image=pil_img, dark_image=pil_img, size=(90, 90))

        lbl_logo = ctk.CTkLabel(card, image=self.logo_img, text="")
        lbl_logo.pack(pady=(25, 5))

        lbl_title = ctk.CTkLabel(
            card, text=COMPANY_NAME.upper(),
            font=ctk.CTkFont(family="Segoe UI", size=22, weight="bold"),
            text_color=COLOR_TEXT_PRIMARY
        )
        lbl_title.pack()

        lbl_sub = ctk.CTkLabel(
            card, text="Acceso al Sistema ERP / CRM",
            font=ctk.CTkFont(family="Segoe UI", size=12),
            text_color=COLOR_TEXT_MUTED
        )
        lbl_sub.pack(pady=(0, 20))

        # Campos de entrada limpios
        self.entry_user = ctk.CTkEntry(card, placeholder_text="Usuario (ej. admin, compras, contador)", width=320, height=42)
        self.entry_user.pack(pady=8, padx=30)

        self.entry_pass = ctk.CTkEntry(card, placeholder_text="Contraseña", show="•", width=320, height=42)
        self.entry_pass.pack(pady=8, padx=30)
        self.entry_pass.bind("<Return>", lambda event: self._login())

        # Label de error / estado
        self.lbl_error = ctk.CTkLabel(card, text="", font=ctk.CTkFont(size=11, weight="bold"), text_color=COLOR_DANGER)
        self.lbl_error.pack(pady=4)

        # Botón Iniciar Sesión
        self.btn_login = ctk.CTkButton(
            card, text="INICIAR SESIÓN", command=self._login,
            fg_color=COLOR_PRIMARY, hover_color=COLOR_PRIMARY_HOVER,
            text_color=COLOR_TEXT_PRIMARY, font=ctk.CTkFont(family="Segoe UI", size=13, weight="bold"),
            width=320, height=46, corner_radius=8
        )
        self.btn_login.pack(pady=(10, 25))

    def _login(self):
        username = self.entry_user.get().strip()
        password = self.entry_pass.get().strip()

        if not username or not password:
            self.lbl_error.configure(text="⚠️ Ingrese su usuario y contraseña")
            return

        user = UserModel.authenticate(username, password)
        if user:
            self.login_attempts = 0
            AuditLogModel.log(
                user['nombre_completo'],
                "Inicio de Sesión",
                f"Acceso exitoso al sistema con el rol '{user['rol']}'"
            )
            self.on_login_success(user)
        else:
            self.login_attempts += 1
            if self.login_attempts >= 3:
                self.lbl_error.configure(text="❌ 3 INTENTOS FALLIDOS. CERRANDO POR SEGURIDAD...")
                self.btn_login.configure(state="disabled", fg_color="#475569")
                self.entry_user.configure(state="disabled")
                self.entry_pass.configure(state="disabled")

                AuditLogModel.log(
                    "SISTEMA DE SEGURIDAD",
                    "Bloqueo por Intentos Fallidos",
                    f"3 intentos de inicio de sesión fallidos alcanzados para usuario '{username}'. Cierre automático de aplicación."
                )
                self.after(1200, self._close_application)
            else:
                self.lbl_error.configure(text=f"❌ Credenciales incorrectas ({self.login_attempts}/3 intentos fallidos)")

    def _close_application(self):
        root = self.winfo_toplevel()
        root.destroy()
        sys.exit(0)
