import customtkinter as ctk
from views.components import PrimaryButton, AccentButton
from config import (
    COLOR_BG_MAIN, COLOR_BG_CARD, COLOR_TEXT_PRIMARY, COLOR_TEXT_MUTED,
    COLOR_ACCENT, COLOR_SUCCESS, COLOR_DANGER, COLOR_WARNING
)
from models.models import UserModel, AuditLogModel

class UsersView(ctk.CTkFrame):
    """ Vista de Gestión de Usuarios (RF1.4) y Registro de Auditoría (RF1.3) """
    @property
    def current_user(self):
        root = self.winfo_toplevel()
        if hasattr(root, 'current_user') and root.current_user:
            return root.current_user
        return {}

    def __init__(self, master, current_user=None, **kwargs):
        super().__init__(master, fg_color=COLOR_BG_MAIN, corner_radius=0, **kwargs)

        top_bar = ctk.CTkFrame(self, fg_color=COLOR_BG_CARD, height=60, corner_radius=0)
        top_bar.pack(fill="x", side="top")

        lbl_t = ctk.CTkLabel(
            top_bar, text="🛡️ Control de Acceso, Usuarios y Bitácora de Auditoría",
            font=ctk.CTkFont(family="Segoe UI", size=16, weight="bold"),
            text_color=COLOR_TEXT_PRIMARY
        )
        lbl_t.pack(side="left", padx=20)

        btn_new = PrimaryButton(top_bar, "Registrar Nuevo Trabajador", icon="👤", command=self.open_new_user_dialog)
        btn_new.pack(side="right", padx=20, pady=12)

        # Tabview para dividir Gestión de Usuarios y Bitácora
        self.tabview = ctk.CTkTabview(self, fg_color=COLOR_BG_MAIN, segmented_button_fg_color=COLOR_BG_CARD, segmented_button_selected_color=COLOR_ACCENT)
        self.tabview.pack(fill="both", expand=True, padx=20, pady=10)

        self.tab_users = self.tabview.add("Gestión de Usuarios (RF1.4)")
        self.tab_audit = self.tabview.add("Bitácora de Auditoría (RF1.3)")

        self.load_users()
        self.load_audit_logs()

    def load_users(self):
        for w in self.tab_users.winfo_children():
            w.destroy()

        scroll = ctk.CTkScrollableFrame(self.tab_users, fg_color="transparent")
        scroll.pack(fill="both", expand=True)

        users = UserModel.get_all()

        for u in users:
            card = ctk.CTkFrame(scroll, fg_color=COLOR_BG_CARD, corner_radius=10, border_width=1, border_color="#1E293B")
            card.pack(fill="x", pady=6)

            left_box = ctk.CTkFrame(card, fg_color="transparent")
            left_box.pack(side="left", padx=16, pady=12)

            name_lbl = ctk.CTkLabel(
                left_box, text=f"{u['nombre_completo']} (@{u['username']})",
                font=ctk.CTkFont(family="Segoe UI", size=14, weight="bold"),
                text_color=COLOR_TEXT_PRIMARY
            )
            name_lbl.pack(anchor="w")

            role_lbl = ctk.CTkLabel(
                left_box,
                text=f"Perfil / Rol: {u['rol']} | Email: {u['email'] or 'N/A'} | Creado: {str(u['fecha_creacion'])[:10]}",
                font=ctk.CTkFont(size=11), text_color=COLOR_TEXT_MUTED
            )
            role_lbl.pack(anchor="w", pady=(2, 0))

            right_box = ctk.CTkFrame(card, fg_color="transparent")
            right_box.pack(side="right", padx=16, pady=12)

            is_active = bool(u['activo'])
            status_txt = "ACTIVO" if is_active else "INACTIVO"
            status_col = COLOR_SUCCESS if is_active else COLOR_DANGER

            st_badge = ctk.CTkLabel(
                right_box, text=status_txt,
                font=ctk.CTkFont(size=11, weight="bold"),
                text_color=status_col, fg_color="#0F172A",
                corner_radius=6, padx=10, pady=4
            )
            st_badge.pack(side="left", padx=(0, 10))

            btn_toggle_txt = "Desactivar" if is_active else "Activar"
            btn_toggle = AccentButton(
                right_box, btn_toggle_txt,
                command=lambda uid=u['id'], st=u['activo'], uname=u['nombre_completo']: self.toggle_user_status(uid, st, uname),
                width=90
            )
            btn_toggle.pack(side="left")

    def toggle_user_status(self, user_id, current_status, user_name):
        UserModel.toggle_active(user_id, current_status)
        new_st_str = "Desactivado" if current_status == 1 else "Activado"
        
        # Auditoría (RF1.3)
        AuditLogModel.log(
            self.current_user.get('nombre_completo', 'Administrador'),
            "Gestión de Usuarios",
            f"Se cambió el estado del usuario '{user_name}' a {new_st_str}"
        )
        self.load_users()
        self.load_audit_logs()

    def open_new_user_dialog(self):
        dialog = ctk.CTkToplevel(self)
        dialog.title("Registrar Trabajador - Inego Industrias")
        dialog.geometry("450x520")
        dialog.configure(fg_color=COLOR_BG_CARD)
        dialog.grab_set()

        ctk.CTkLabel(dialog, text="NUEVAS CREDENCIALES DE TRABAJADOR", font=ctk.CTkFont(size=14, weight="bold"), text_color=COLOR_TEXT_PRIMARY).pack(pady=15)

        e_user = ctk.CTkEntry(dialog, placeholder_text="Nombre de Usuario (ej. jgomez)", width=350)
        e_user.pack(pady=6)

        e_pass = ctk.CTkEntry(dialog, placeholder_text="Contraseña", show="•", width=350)
        e_pass.pack(pady=6)

        e_nom = ctk.CTkEntry(dialog, placeholder_text="Nombre Completo del Trabajador/Socio", width=350)
        e_nom.pack(pady=6)

        e_email = ctk.CTkEntry(dialog, placeholder_text="Correo Electrónico", width=350)
        e_email.pack(pady=6)

        ctk.CTkLabel(dialog, text="Perfil / Rol Operativo:", text_color=COLOR_TEXT_MUTED).pack(anchor="w", padx=50, pady=(6, 0))
        e_rol = ctk.CTkOptionMenu(
            dialog,
            values=["Administrador de Dinero", "Compras y Mercadería", "Contabilidad"],
            width=350
        )
        e_rol.pack(pady=6)

        def save():
            user = e_user.get().strip()
            pwd = e_pass.get().strip()
            nom = e_nom.get().strip()
            rol = e_rol.get()
            if user and pwd and nom:
                UserModel.create_user(user, pwd, nom, e_email.get().strip(), rol)
                AuditLogModel.log(
                    self.current_user.get('nombre_completo', 'Administrador'),
                    "Creación de Usuario",
                    f"Creación de credenciales para '{nom}' con el rol '{rol}'"
                )
                dialog.destroy()
                self.load_users()
                self.load_audit_logs()

        btn_save = PrimaryButton(dialog, "Guardar Credenciales", command=save, width=350)
        btn_save.pack(pady=20)

    def load_audit_logs(self):
        for w in self.tab_audit.winfo_children():
            w.destroy()

        scroll = ctk.CTkScrollableFrame(self.tab_audit, fg_color="transparent")
        scroll.pack(fill="both", expand=True)

        logs = AuditLogModel.get_all()

        if not logs:
            ctk.CTkLabel(scroll, text="No hay registros de auditoría aún.", text_color=COLOR_TEXT_MUTED).pack(pady=30)
            return

        for l in logs:
            row = ctk.CTkFrame(scroll, fg_color=COLOR_BG_CARD, corner_radius=8, border_width=1, border_color="#1E293B")
            row.pack(fill="x", pady=4)

            left_box = ctk.CTkFrame(row, fg_color="transparent")
            left_box.pack(side="left", padx=14, pady=8)

            action_lbl = ctk.CTkLabel(
                left_box, text=f"📌 {l['tipo_accion']} | {l['usuario_nombre']}",
                font=ctk.CTkFont(family="Segoe UI", size=13, weight="bold"),
                text_color=COLOR_TEXT_PRIMARY
            )
            action_lbl.pack(anchor="w")

            det_lbl = ctk.CTkLabel(
                left_box, text=f"Detalles: {l['detalles']}",
                font=ctk.CTkFont(size=11), text_color=COLOR_TEXT_MUTED
            )
            det_lbl.pack(anchor="w", pady=(1, 0))

            time_lbl = ctk.CTkLabel(
                row, text=str(l['fecha_hora']),
                font=ctk.CTkFont(size=11, weight="bold"), text_color=COLOR_ACCENT
            )
            time_lbl.pack(side="right", padx=14)

    def refresh_data(self):
        self.load_users()
        self.load_audit_logs()
