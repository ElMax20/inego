import customtkinter as ctk
import webbrowser
import os
from views.components import PrimaryButton, AccentButton
from config import COLOR_BG_MAIN, COLOR_BG_CARD, COLOR_TEXT_PRIMARY, COLOR_TEXT_MUTED, COLOR_ACCENT, COLOR_SUCCESS, COLOR_WARNING, DATA_DIR
from models.models import ClientModel, ProductModel, SupplierModel, QuoteModel
from utils.pdf_generator import generate_quote_pdf
from database.connection import db

class QuotesView(ctk.CTkFrame):
    def __init__(self, master, **kwargs):
        super().__init__(master, fg_color=COLOR_BG_MAIN, corner_radius=0, **kwargs)

        top_bar = ctk.CTkFrame(self, fg_color=COLOR_BG_CARD, height=60, corner_radius=0)
        top_bar.pack(fill="x", side="top")

        lbl_t = ctk.CTkLabel(
            top_bar, text="📋 Cotizador e Historial de Cotizaciones",
            font=ctk.CTkFont(family="Segoe UI", size=16, weight="bold"),
            text_color=COLOR_TEXT_PRIMARY
        )
        lbl_t.pack(side="left", padx=20)

        btn_new = PrimaryButton(top_bar, "Nueva Cotización Multi-Proveedor", icon="➕", command=self.open_new_quote_dialog)
        btn_new.pack(side="right", padx=20, pady=12)

        self.scroll = ctk.CTkScrollableFrame(self, fg_color="transparent")
        self.scroll.pack(fill="both", expand=True, padx=20, pady=20)

        self.load_quotes()

    def load_quotes(self):
        for w in self.scroll.winfo_children():
            w.destroy()

        quotes = QuoteModel.get_all()

        if not quotes:
            ctk.CTkLabel(self.scroll, text="No hay cotizaciones registradas.", text_color=COLOR_TEXT_MUTED).pack(pady=30)
            return

        for q in quotes:
            card = ctk.CTkFrame(self.scroll, fg_color=COLOR_BG_CARD, corner_radius=10, border_width=1, border_color="#1E293B")
            card.pack(fill="x", pady=6)

            left_box = ctk.CTkFrame(card, fg_color="transparent")
            left_box.pack(side="left", padx=16, pady=12)

            num_lbl = ctk.CTkLabel(
                left_box, text=f"Cotización N° {q['numero_cotizacion']} - {q['razon_social_nombre']}",
                font=ctk.CTkFont(family="Segoe UI", size=14, weight="bold"),
                text_color=COLOR_TEXT_PRIMARY
            )
            num_lbl.pack(anchor="w")

            cred_str = "Crédito 72 Días (B2B)" if q['es_credito_72dias'] else "Contado (B2C)"
            info_lbl = ctk.CTkLabel(
                left_box,
                text=f"Emisión: {q['fecha_emision']} | Vencimiento: {q['fecha_vencimiento']} | Condición: {cred_str} | Estado: {q['estado']}",
                font=ctk.CTkFont(size=11), text_color=COLOR_TEXT_MUTED
            )
            info_lbl.pack(anchor="w", pady=(2, 0))

            right_box = ctk.CTkFrame(card, fg_color="transparent")
            right_box.pack(side="right", padx=16, pady=12)

            tot_lbl = ctk.CTkLabel(
                right_box, text=f"${float(q['total']):,.2f} USD",
                font=ctk.CTkFont(size=16, weight="bold"), text_color=COLOR_ACCENT
            )
            tot_lbl.pack(side="left", padx=(0, 15))

            btn_pdf = AccentButton(right_box, "PDF", command=lambda qid=q['id']: self.export_pdf(qid), width=70)
            btn_pdf.pack(side="left", padx=3)

            btn_wa = PrimaryButton(right_box, "WhatsApp", command=lambda num=q['numero_cotizacion'], tot=float(q['total']): self.open_wa(num, tot), width=90)
            btn_wa.pack(side="left", padx=3)

    def export_pdf(self, quote_id):
        pdf_path = generate_quote_pdf(quote_id)
        if pdf_path and os.path.exists(pdf_path):
            os.startfile(pdf_path)

    def open_wa(self, numero_cotizacion, total_usd):
        url = QuoteModel.generate_whatsapp_link("0990000000", numero_cotizacion, total_usd)
        webbrowser.open(url)

    def open_new_quote_dialog(self):
        dialog = ctk.CTkToplevel(self)
        dialog.title("Nueva Cotización - Inego Industrias")
        dialog.geometry("650x600")
        dialog.configure(fg_color=COLOR_BG_CARD)
        dialog.grab_set()

        ctk.CTkLabel(dialog, text="GENERADOR DE COTIZACIONES", font=ctk.CTkFont(size=14, weight="bold"), text_color=COLOR_TEXT_PRIMARY).pack(pady=10)

        clients = ClientModel.get_all()
        client_map = {f"{c['razon_social_nombre']} ({c['tipo_cliente']})": c for c in clients}
        client_names = list(client_map.keys()) or ["Sin clientes registrados"]

        ctk.CTkLabel(dialog, text="Seleccione Cliente:", text_color=COLOR_TEXT_MUTED).pack(anchor="w", padx=20)
        c_menu = ctk.CTkOptionMenu(dialog, values=client_names, width=580)
        c_menu.pack(pady=5)

        ctk.CTkLabel(dialog, text="Items a Cotizar:", font=ctk.CTkFont(weight="bold"), text_color=COLOR_TEXT_PRIMARY).pack(anchor="w", padx=20, pady=(10, 0))

        items_frame = ctk.CTkScrollableFrame(dialog, height=180, fg_color="#0F172A")
        items_frame.pack(fill="x", padx=20, pady=5)

        selected_items = []

        def render_items():
            for w in items_frame.winfo_children():
                w.destroy()
            for idx, it in enumerate(selected_items):
                row = ctk.CTkFrame(items_frame, fg_color="#1E293B")
                row.pack(fill="x", pady=2)
                lbl = ctk.CTkLabel(row, text=f"• {it['nombre']} | Cant: {it['cantidad']} | P. Venta: ${it['precio_venta']:,.2f}", text_color=COLOR_TEXT_PRIMARY)
                lbl.pack(side="left", padx=10)

        add_box = ctk.CTkFrame(dialog, fg_color="transparent")
        add_box.pack(fill="x", padx=20, pady=5)

        prods = ProductModel.get_all()
        prod_map = {f"{p['codigo']} - {p['nombre']}": p for p in prods}
        prod_names = list(prod_map.keys()) or ["Sin productos"]

        p_menu = ctk.CTkOptionMenu(add_box, values=prod_names, width=280)
        p_menu.pack(side="left", padx=(0, 5))

        e_cant = ctk.CTkEntry(add_box, placeholder_text="Cant", width=70)
        e_cant.pack(side="left", padx=2)
        e_cant.insert(0, "1")

        e_pv = ctk.CTkEntry(add_box, placeholder_text="P. Venta USD", width=90)
        e_pv.pack(side="left", padx=2)
        e_pv.insert(0, "15.00")

        def add_item():
            p_sel = prod_map.get(p_menu.get())
            if p_sel:
                try:
                    cant = int(e_cant.get())
                    pv = float(e_pv.get())
                    selected_items.append({
                        "producto_id": p_sel['id'],
                        "nombre": p_sel['nombre'],
                        "cantidad": cant,
                        "precio_venta": pv,
                        "precio_costo": pv * 0.7
                    })
                    render_items()
                except ValueError:
                    pass

        btn_add_it = AccentButton(add_box, "+ Item", command=add_item, width=80)
        btn_add_it.pack(side="left", padx=5)

        e_obs = ctk.CTkEntry(dialog, placeholder_text="Observaciones (ej. Contrato Gobierno N° 45 / Entregas en Guayaquil)", width=580)
        e_obs.pack(pady=10)

        def save_quote():
            c_sel = client_map.get(c_menu.get())
            if c_sel and selected_items:
                is_b2b = c_sel['tipo_cliente'] == 'B2B'
                QuoteModel.create_quote(c_sel['id'], is_b2b, selected_items, e_obs.get().strip())
                dialog.destroy()
                self.load_quotes()

        btn_save = PrimaryButton(dialog, "Generar Cotización Oficial", command=save_quote, width=580)
        btn_save.pack(pady=15)
