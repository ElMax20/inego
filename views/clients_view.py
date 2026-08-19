import customtkinter as ctk
from views.components import PrimaryButton, AccentButton
from config import COLOR_BG_MAIN, COLOR_BG_CARD, COLOR_TEXT_PRIMARY, COLOR_TEXT_MUTED, COLOR_ACCENT, COLOR_WARNING, COLOR_SUCCESS, COLOR_DANGER
from models.models import ClientModel
from database.connection import db

class ClientsView(ctk.CTkFrame):
    def __init__(self, master, **kwargs):
        super().__init__(master, fg_color=COLOR_BG_MAIN, corner_radius=0, **kwargs)

        top_bar = ctk.CTkFrame(self, fg_color=COLOR_BG_CARD, height=60, corner_radius=0)
        top_bar.pack(fill="x", side="top")

        lbl_t = ctk.CTkLabel(
            top_bar, text="👥 Gestión de Clientes y Políticas de Crédito",
            font=ctk.CTkFont(family="Segoe UI", size=16, weight="bold"),
            text_color=COLOR_TEXT_PRIMARY
        )
        lbl_t.pack(side="left", padx=20)

        btn_new = PrimaryButton(top_bar, "Registrar Nuevo Cliente", icon="➕", command=self.open_new_client_dialog)
        btn_new.pack(side="right", padx=20, pady=12)

        self.scroll = ctk.CTkScrollableFrame(self, fg_color="transparent")
        self.scroll.pack(fill="both", expand=True, padx=20, pady=20)

        self.load_clients()

    def load_clients(self):
        for w in self.scroll.winfo_children():
            w.destroy()

        clients = ClientModel.get_all()

        for c in clients:
            card = ctk.CTkFrame(self.scroll, fg_color=COLOR_BG_CARD, corner_radius=10, border_width=1, border_color="#1E293B")
            card.pack(fill="x", pady=6)

            left_box = ctk.CTkFrame(card, fg_color="transparent")
            left_box.pack(side="left", padx=16, pady=12)

            name_lbl = ctk.CTkLabel(
                left_box, text=f"{c['razon_social_nombre']} ({c['tipo_cliente']})",
                font=ctk.CTkFont(family="Segoe UI", size=14, weight="bold"),
                text_color=COLOR_TEXT_PRIMARY
            )
            name_lbl.pack(anchor="w")

            info_lbl = ctk.CTkLabel(
                left_box,
                text=f"RUC/Cédula: {c['ruc_cedula'] or 'N/A'} | Tel: {c['telefono']} | Email: {c['email']} | Dir: {c['direccion']}",
                font=ctk.CTkFont(size=11), text_color=COLOR_TEXT_MUTED
            )
            info_lbl.pack(anchor="w", pady=(2, 0))

            right_box = ctk.CTkFrame(card, fg_color="transparent")
            right_box.pack(side="right", padx=16, pady=12)

            is_b2b = c['tipo_cliente'] == 'B2B'
            badge_txt = "Crédito Concedido: 72 Días" if is_b2b else "Sin Crédito (Pago al Contado)"
            badge_color = COLOR_WARNING if is_b2b else COLOR_SUCCESS

            badge = ctk.CTkLabel(
                right_box, text=badge_txt,
                font=ctk.CTkFont(size=12, weight="bold"),
                text_color=badge_color, fg_color="#0F172A", corner_radius=6, padx=10, pady=4
            )
            badge.pack(side="left", padx=(0, 10))

            btn_hist = AccentButton(right_box, "Historial", command=lambda cid=c['id'], cname=c['razon_social_nombre']: self.show_history(cid, cname), width=90)
            btn_hist.pack(side="left")

    def show_history(self, client_id, client_name):
        dialog = ctk.CTkToplevel(self)
        dialog.title(f"Historial de Cotizaciones - {client_name}")
        dialog.geometry("600x400")
        dialog.configure(fg_color=COLOR_BG_CARD)
        dialog.grab_set()

        ctk.CTkLabel(dialog, text=f"HISTORIAL DE COTIZACIONES: {client_name}", font=ctk.CTkFont(size=13, weight="bold"), text_color=COLOR_TEXT_PRIMARY).pack(pady=10)

        scroll = ctk.CTkScrollableFrame(dialog, fg_color="transparent")
        scroll.pack(fill="both", expand=True, padx=15, pady=10)

        history = ClientModel.get_quotes_history(client_id)
        if not history:
            ctk.CTkLabel(scroll, text="No hay cotizaciones previas para este cliente.", text_color=COLOR_TEXT_MUTED).pack(pady=20)
            return

        for q in history:
            row = ctk.CTkFrame(scroll, fg_color="#1E293B", corner_radius=6)
            row.pack(fill="x", pady=4, padx=5)

            lbl = ctk.CTkLabel(row, text=f"• N° {q['numero_cotizacion']} | Fecha: {q['fecha_emision']} | Total: ${q['total']:,.2f}", font=ctk.CTkFont(size=12), text_color=COLOR_TEXT_PRIMARY)
            lbl.pack(side="left", padx=10, pady=6)

            st_lbl = ctk.CTkLabel(row, text=f"Estado: {q['estado']}", font=ctk.CTkFont(size=12, weight="bold"), text_color=COLOR_ACCENT)
            st_lbl.pack(side="right", padx=10, pady=6)

    def open_new_client_dialog(self):
        dialog = ctk.CTkToplevel(self)
        dialog.title("Nuevo Cliente - Inego Industrias")
        dialog.geometry("450x480")
        dialog.configure(fg_color=COLOR_BG_CARD)
        dialog.grab_set()

        ctk.CTkLabel(dialog, text="REGISTRAR NUEVO CLIENTE", font=ctk.CTkFont(size=14, weight="bold"), text_color=COLOR_TEXT_PRIMARY).pack(pady=15)

        e_tipo = ctk.CTkOptionMenu(dialog, values=["B2B", "B2C"], width=350)
        e_tipo.pack(pady=6)

        e_nom = ctk.CTkEntry(dialog, placeholder_text="Razón Social / Nombre Completo", width=350)
        e_nom.pack(pady=6)

        e_ruc = ctk.CTkEntry(dialog, placeholder_text="RUC / Cédula", width=350)
        e_ruc.pack(pady=6)

        e_tel = ctk.CTkEntry(dialog, placeholder_text="Teléfono / WhatsApp", width=350)
        e_tel.pack(pady=6)

        e_email = ctk.CTkEntry(dialog, placeholder_text="Correo Electrónico (Gmail/Corporativo)", width=350)
        e_email.pack(pady=6)

        e_dir = ctk.CTkEntry(dialog, placeholder_text="Dirección (Guayaquil)", width=350)
        e_dir.pack(pady=6)
        e_dir.insert(0, "Guayaquil")

        lbl_err = ctk.CTkLabel(dialog, text="", font=ctk.CTkFont(size=11, weight="bold"), text_color=COLOR_DANGER)
        lbl_err.pack(pady=4)

        def save():
            tipo = e_tipo.get()
            nom = e_nom.get().strip()
            ruc_ced = e_ruc.get().strip()
            tel = e_tel.get().strip()
            email = e_email.get().strip()
            direccion = e_dir.get().strip()

            from utils.validators import validate_email, validate_phone, validate_cedula, validate_ruc, validate_required_fields

            # 1. Campos obligatorios
            ok_req, msg_req = validate_required_fields({
                "Razón Social / Nombre": nom,
                "RUC / Cédula": ruc_ced,
                "Teléfono": tel,
                "Correo Electrónico": email,
                "Dirección": direccion
            })
            if not ok_req:
                lbl_err.configure(text=f"⚠️ {msg_req}")
                return

            # 2. RUC (13) o Cédula (10)
            if len(ruc_ced) == 13:
                ok_doc, msg_doc = validate_ruc(ruc_ced)
            else:
                ok_doc, msg_doc = validate_cedula(ruc_ced)

            if not ok_doc:
                lbl_err.configure(text=f"⚠️ {msg_doc}")
                return

            # 3. Teléfono (10 dígitos)
            ok_tel, msg_tel = validate_phone(tel)
            if not ok_tel:
                lbl_err.configure(text=f"⚠️ {msg_tel}")
                return

            # 4. Email (@gmail.com / @hotmail)
            ok_email, msg_email = validate_email(email)
            if not ok_email:
                lbl_err.configure(text=f"⚠️ {msg_email}")
                return

            ClientModel.create(tipo, nom, ruc_ced, tel, email, direccion)
            dialog.destroy()
            self.load_clients()

        btn_save = PrimaryButton(dialog, "Guardar Cliente", command=save, width=350)
        btn_save.pack(pady=12)

    def refresh_data(self):
        try:
            from database.connection import db
            count_row = db.fetch_one("SELECT COUNT(*) as cnt FROM clientes")
            total_cls = count_row['cnt'] if count_row else 0
            if not hasattr(self, '_cached_clients_count') or self._cached_clients_count != total_cls:
                self._cached_clients_count = total_cls
                self.load_clients()
        except Exception:
            self.load_clients()
