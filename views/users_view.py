import customtkinter as ctk
import threading
from views.components import PrimaryButton, AccentButton
from config import (
    COLOR_BG_MAIN, COLOR_BG_CARD, COLOR_TEXT_PRIMARY, COLOR_TEXT_MUTED,
    COLOR_ACCENT, COLOR_SUCCESS, COLOR_DANGER, COLOR_WARNING
)
from models.models import UserModel, AuditLogModel
from utils.validators import validate_email, validate_required_fields
from database.connection import db

class UsersView(ctk.CTkFrame):
    """ Vista de Gestión de Usuarios (RF1.4) y Registro de Auditoría (RF1.3) optimizada al extremo """
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

        # Botón Registrar Nuevo Trabajador (Solo visible/habilitado para Administradores)
        user_rol = self.current_user.get('rol', '')
        user_name = self.current_user.get('username', '')
        self.is_admin = (user_rol == 'Administrador de Dinero' or user_name == 'admin')

        if self.is_admin:
            btn_new = PrimaryButton(top_bar, "Registrar Nuevo Trabajador", icon="👤", command=self.open_new_user_dialog)
            btn_new.pack(side="right", padx=20, pady=12)

        # Tabview para dividir Gestión de Usuarios y Bitácora
        self.tabview = ctk.CTkTabview(self, fg_color=COLOR_BG_MAIN, segmented_button_fg_color=COLOR_BG_CARD, segmented_button_selected_color=COLOR_ACCENT)
        self.tabview.pack(fill="both", expand=True, padx=20, pady=10)

        self.tab_users = self.tabview.add("Gestión de Usuarios (RF1.4)")
        self.tab_audit = self.tabview.add("Bitácora de Auditoría (RF1.3)")

        # Inicialización de contenedores scroll de forma fija y única
        self.users_scroll = ctk.CTkScrollableFrame(self.tab_users, fg_color="transparent")
        self.users_scroll.pack(fill="both", expand=True)

        # Usar una única caja de texto ultra-optimizada para la bitácora (1 sola ventana en vez de cientos de widgets)
        self.audit_text = ctk.CTkTextbox(self.tab_audit, fg_color="#090D16", font=ctk.CTkFont(family="Consolas", size=12), text_color="#E2E8F0", activate_scrollbars=True)
        self.audit_text.pack(fill="both", expand=True, padx=15, pady=15)
        
        color_acc = COLOR_ACCENT[1] if isinstance(COLOR_ACCENT, tuple) else COLOR_ACCENT
        color_succ = COLOR_SUCCESS[1] if isinstance(COLOR_SUCCESS, tuple) else COLOR_SUCCESS
        self.audit_text.tag_config("time", foreground=color_acc)
        self.audit_text.tag_config("user", foreground="#38BDF8")
        self.audit_text.tag_config("action", foreground=color_succ)
        self.audit_text.tag_config("details", foreground="#94A3B8")
        
        self.rendered_user_count = -1
        self.rendered_log_count = -1

        self.load_users()
        self.load_audit_logs()

    def load_users(self):
        for w in self.users_scroll.winfo_children():
            w.destroy()
            
        lbl_loading = ctk.CTkLabel(self.users_scroll, text="Cargando usuarios...", text_color=COLOR_TEXT_MUTED)
        lbl_loading.pack(pady=20)

        def fetch():
            users = UserModel.get_all()
            self.after(0, lambda: self._render_users(users))
            
        threading.Thread(target=fetch, daemon=True).start()

    def _render_users(self, users):
        for w in self.users_scroll.winfo_children():
            w.destroy()

        if not users:
            ctk.CTkLabel(self.users_scroll, text="No hay usuarios registrados.", text_color=COLOR_TEXT_MUTED).pack(pady=20)
            return

        for u in users:
            card = ctk.CTkFrame(self.users_scroll, fg_color=COLOR_BG_CARD, corner_radius=10, border_width=1, border_color="#1E293B")
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

            # 1. Protección de la cuenta main admin
            if u['username'].lower() == 'admin':
                prot_badge = ctk.CTkLabel(
                    right_box, text="🛡️ Cuenta Admin Protegida",
                    font=ctk.CTkFont(size=11, weight="bold"),
                    text_color=COLOR_ACCENT, fg_color="#0F172A",
                    corner_radius=6, padx=10, pady=4
                )
                prot_badge.pack(side="left")
            # 2. Solo administradores pueden activar/desactivar otros usuarios
            elif self.is_admin:
                btn_toggle_txt = "Desactivar" if is_active else "Activar"
                btn_toggle = AccentButton(
                    right_box, btn_toggle_txt,
                    command=lambda uid=u['id'], st=u['activo'], uname=u['nombre_completo']: self.toggle_user_status(uid, st, uname),
                    width=90
                )
                btn_toggle.pack(side="left")
            else:
                restr_lbl = ctk.CTkLabel(
                    right_box, text="🔒 Solo Administrador",
                    font=ctk.CTkFont(size=11), text_color=COLOR_TEXT_MUTED
                )
                restr_lbl.pack(side="left")

    def toggle_user_status(self, user_id, current_status, user_name):
        if not self.is_admin:
            return

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
        if not self.is_admin:
            return

        dialog = ctk.CTkToplevel(self)
        dialog.title("Registrar Trabajador - Inego Industrias")
        dialog.geometry("450x540")
        dialog.configure(fg_color=COLOR_BG_CARD)
        dialog.grab_set()

        ctk.CTkLabel(dialog, text="NUEVAS CREDENCIALES DE TRABAJADOR", font=ctk.CTkFont(size=14, weight="bold"), text_color=COLOR_TEXT_PRIMARY).pack(pady=12)

        e_user = ctk.CTkEntry(dialog, placeholder_text="Nombre de Usuario (ej. jgomez)", width=350)
        e_user.pack(pady=6)

        e_pass = ctk.CTkEntry(dialog, placeholder_text="Contraseña", show="•", width=350)
        e_pass.pack(pady=6)

        e_nom = ctk.CTkEntry(dialog, placeholder_text="Nombre Completo del Trabajador/Socio", width=350)
        e_nom.pack(pady=6)

        e_email = ctk.CTkEntry(dialog, placeholder_text="Correo (ej. usuario@gmail.com)", width=350)
        e_email.pack(pady=6)

        ctk.CTkLabel(dialog, text="Perfil / Rol Operativo:", text_color=COLOR_TEXT_MUTED).pack(anchor="w", padx=50, pady=(6, 0))
        e_rol = ctk.CTkOptionMenu(
            dialog,
            values=["Administrador de Dinero", "Compras y Mercadería", "Contabilidad"],
            width=350
        )
        e_rol.pack(pady=6)

        lbl_err = ctk.CTkLabel(dialog, text="", font=ctk.CTkFont(size=11, weight="bold"), text_color=COLOR_DANGER)
        lbl_err.pack(pady=4)

        def save():
            user = e_user.get().strip()
            pwd = e_pass.get().strip()
            nom = e_nom.get().strip()
            email = e_email.get().strip()
            rol = e_rol.get()

            ok_req, msg_req = validate_required_fields({
                "Usuario": user,
                "Contraseña": pwd,
                "Nombre Completo": nom,
                "Correo Electrónico": email
            })
            if not ok_req:
                lbl_err.configure(text=f"⚠️ {msg_req}")
                return

            ok_email, msg_email = validate_email(email)
            if not ok_email:
                lbl_err.configure(text=f"⚠️ {msg_email}")
                return

            UserModel.create_user(user, pwd, nom, email, rol)
            AuditLogModel.log(
                self.current_user.get('nombre_completo', 'Administrador'),
                "Creación de Usuario",
                f"Creación de credenciales para '{nom}' con el rol '{rol}'"
            )
            dialog.destroy()
            self.load_users()
            self.load_audit_logs()

        btn_save = PrimaryButton(dialog, "Guardar Credenciales", command=save, width=350)
        btn_save.pack(pady=12)

    def load_audit_logs(self):
        # Muestra mensaje en la propia caja de texto sin destruirla
        self.audit_text.configure(state="normal")
        self.audit_text.delete("1.0", "end")
        self.audit_text.insert("end", "Cargando bitácora de auditoría...\n")
        self.audit_text.configure(state="disabled")

        def fetch():
            logs = AuditLogModel.get_all()
            self.after(0, lambda: self._render_audit_logs(logs))
            
        threading.Thread(target=fetch, daemon=True).start()

    def _render_audit_logs(self, logs):
        self.audit_text.configure(state="normal")
        self.audit_text.delete("1.0", "end")

        if not logs:
            self.audit_text.insert("end", "No hay registros de auditoría aún.\n")
            self.audit_text.configure(state="disabled")
            return

        for l in logs:
            self.audit_text.insert("end", f"[{l['fecha_hora']}] ", "time")
            self.audit_text.insert("end", f"{l['usuario_nombre']} ", "user")
            self.audit_text.insert("end", f"({l['tipo_accion']}): ", "action")
            self.audit_text.insert("end", f"{l['detalles']}\n", "details")
            
        self.audit_text.configure(state="disabled")

    def refresh_data(self):
        # Optimización extrema: Verificar conteo de registros antes de recargar
        try:
            count_row = db.fetch_one("SELECT COUNT(*) as cnt FROM auditoria_log")
            total_logs = count_row['cnt'] if count_row else 0
            if self.rendered_log_count != total_logs:
                self.rendered_log_count = total_logs
                self.load_audit_logs()
        except Exception:
            self.load_audit_logs()

        try:
            users_count_row = db.fetch_one("SELECT COUNT(*) as cnt FROM usuarios")
            total_users = users_count_row['cnt'] if users_count_row else 0
            if self.rendered_user_count != total_users:
                self.rendered_user_count = total_users
                self.load_users()
        except Exception:
            self.load_users()
