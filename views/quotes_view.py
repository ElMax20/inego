import customtkinter as ctk
import webbrowser
import os
from views.components import PrimaryButton, AccentButton
from config import COLOR_BG_MAIN, COLOR_BG_CARD, COLOR_TEXT_PRIMARY, COLOR_TEXT_MUTED, COLOR_ACCENT, COLOR_SUCCESS, COLOR_WARNING, DATA_DIR
from models.models import ClientModel, ProductModel, SupplierModel, QuoteModel, AuditLogModel
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

            btn_logistics = AccentButton(right_box, "📦 Logística", command=lambda quote=q: self.open_logistics_dialog(quote), width=95)
            btn_logistics.pack(side="left", padx=3)

            if q['estado'] == 'Enviada':
                btn_app = PrimaryButton(right_box, "✔️ Aprobar", command=lambda qid=q['id'], num=q['numero_cotizacion']: self.approve_quote(qid, num), width=85)
                btn_app.pack(side="left", padx=3)
                
                btn_rej = AccentButton(right_box, "❌ Rechazar", command=lambda qid=q['id'], num=q['numero_cotizacion']: self.reject_quote(qid, num), width=85)
                btn_rej.pack(side="left", padx=3)
                
            elif q['estado'] == 'Aprobada':
                btn_conv = PrimaryButton(right_box, "📝 Orden Venta", command=lambda qid=q['id'], num=q['numero_cotizacion']: self.convert_quote_to_sale(qid, num), width=105)
                btn_conv.pack(side="left", padx=3)

    def export_pdf(self, quote_id):
        pdf_path = generate_quote_pdf(quote_id)
        if pdf_path and os.path.exists(pdf_path):
            os.startfile(pdf_path)

    def open_wa(self, numero_cotizacion, total_usd):
        url = QuoteModel.generate_whatsapp_link("0990000000", numero_cotizacion, total_usd)
        webbrowser.open(url)

    def approve_quote(self, quote_id, num):
        QuoteModel.update_status(quote_id, "Aprobada")
        root_win = self.winfo_toplevel()
        user_name = root_win.current_user.get('nombre_completo', 'Socio 1 - Administrador de Dinero') if hasattr(root_win, 'current_user') and root_win.current_user else 'Socio 1 - Administrador de Dinero'
        AuditLogModel.log(user_name, "Aprobación Cotización", f"Cotización N° {num} aprobada para venta.")
        self.load_quotes()

    def reject_quote(self, quote_id, num):
        QuoteModel.update_status(quote_id, "Rechazada")
        root_win = self.winfo_toplevel()
        user_name = root_win.current_user.get('nombre_completo', 'Socio 1 - Administrador de Dinero') if hasattr(root_win, 'current_user') and root_win.current_user else 'Socio 1 - Administrador de Dinero'
        AuditLogModel.log(user_name, "Rechazo Cotización", f"Cotización N° {num} rechazada.")
        self.load_quotes()

    def convert_quote_to_sale(self, quote_id, num):
        query_details = """
            SELECT d.*, p.nombre, p.tipo_stock, p.stock_actual
            FROM cotizacion_detalles d
            JOIN productos p ON d.producto_id = p.id
            WHERE d.cotizacion_id = %s
        """
        details = db.fetch_all(query_details, (quote_id,))
        
        insufficient_stock = []
        for item in details:
            if item['tipo_stock'] == 'Permanente' and item['cantidad'] > item['stock_actual']:
                insufficient_stock.append(f"{item['nombre']} (Requiere: {item['cantidad']}, Disponible: {item['stock_actual']})")
        
        if insufficient_stock:
            from tkinter import messagebox
            messagebox.showerror(
                "Stock Insuficiente", 
                "No se puede realizar la conversión a Orden de Venta. Stock insuficiente:\n\n" + "\n".join(insufficient_stock)
            )
            return

        for item in details:
            if item['tipo_stock'] == 'Permanente':
                ProductModel.update_stock(item['producto_id'], -item['cantidad'])
                
        numero_orden = QuoteModel.convert_to_sales_order(quote_id)
        
        root_win = self.winfo_toplevel()
        user_name = root_win.current_user.get('nombre_completo', 'Socio 1 - Administrador de Dinero') if hasattr(root_win, 'current_user') and root_win.current_user else 'Socio 1 - Administrador de Dinero'
        AuditLogModel.log(
            user_name,
            "Despacho",
            f"Orden de Venta {numero_orden} generada a partir de Cotización N° {num}. Stock de bodega deducido."
        )
        
        from tkinter import messagebox
        messagebox.showinfo("Conversión Exitosa", f"¡Cotización convertida con éxito a Orden de Venta {numero_orden}!")
        self.load_quotes()

    def open_new_quote_dialog(self):
        dialog = ctk.CTkToplevel(self)
        dialog.title("Nueva Cotización Express - Inego Industrias")
        dialog.geometry("680x650")
        dialog.configure(fg_color=COLOR_BG_CARD)
        dialog.grab_set()

        ctk.CTkLabel(dialog, text="GENERADOR DE COTIZACIONES EXPRESS", font=ctk.CTkFont(size=14, weight="bold"), text_color=COLOR_TEXT_PRIMARY).pack(pady=10)

        clients = ClientModel.get_all()
        client_map = {f"{c['razon_social_nombre']} ({c['tipo_cliente']})": c for c in clients}
        client_names = list(client_map.keys()) or ["Sin clientes registrados"]

        ctk.CTkLabel(dialog, text="Seleccione Cliente:", text_color=COLOR_TEXT_MUTED).pack(anchor="w", padx=20)
        c_menu = ctk.CTkOptionMenu(dialog, values=client_names, width=640)
        c_menu.pack(pady=5)

        ctk.CTkLabel(dialog, text="Items a Cotizar:", font=ctk.CTkFont(weight="bold"), text_color=COLOR_TEXT_PRIMARY).pack(anchor="w", padx=20, pady=(10, 0))

        items_frame = ctk.CTkScrollableFrame(dialog, height=160, fg_color="#0F172A")
        items_frame.pack(fill="x", padx=20, pady=5)

        selected_items = []

        def render_items():
            for w in items_frame.winfo_children():
                w.destroy()
            for idx, it in enumerate(selected_items):
                row = ctk.CTkFrame(items_frame, fg_color="#1E293B")
                row.pack(fill="x", pady=2)
                lbl = ctk.CTkLabel(row, text=f"• {it['nombre']} | Cant: {it['cantidad']} | Costo Ref: ${it['precio_costo']:,.2f} | P. Venta: ${it['precio_venta']:,.2f} | Subtotal: ${it['cantidad']*it['precio_venta']:,.2f}", text_color=COLOR_TEXT_PRIMARY)
                lbl.pack(side="left", padx=10)

        # Resumen de Impuestos y Total
        lbl_summary = ctk.CTkLabel(
            dialog, 
            text="Subtotal: $0.00 USD | IVA (15%): $0.00 USD | Total: $0.00 USD", 
            font=ctk.CTkFont(size=12, weight="bold"), 
            text_color=COLOR_ACCENT
        )
        lbl_summary.pack(pady=5)

        def update_tax_summary():
            sub = sum(it['cantidad'] * it['precio_venta'] for it in selected_items)
            iva = sub * 0.15
            tot = sub + iva
            lbl_summary.configure(text=f"Subtotal: ${sub:,.2f} USD | IVA (15%): ${iva:,.2f} USD | Total: ${tot:,.2f} USD")

        add_box = ctk.CTkFrame(dialog, fg_color="transparent")
        add_box.pack(fill="x", padx=20, pady=5)

        prods = ProductModel.get_all()
        prod_map = {f"{p['codigo']} - {p['nombre']}": p for p in prods}
        prod_names = list(prod_map.keys()) or ["Sin productos"]

        lbl_cost_info = ctk.CTkLabel(dialog, text="Costo Ref: $0.00 USD (Margen % aplicable)", font=ctk.CTkFont(size=11), text_color=COLOR_TEXT_MUTED)
        lbl_cost_info.pack(anchor="w", padx=20, pady=(2, 0))

        def update_cost_preview(*args):
            p_sel = prod_map.get(p_menu.get())
            if p_sel:
                linked = SupplierModel.get_product_suppliers(p_sel['id'])
                if linked:
                    cost = float(linked[0]['precio_cotizado'])
                    lbl_cost_info.configure(text=f"Costo Proveedor Mínimo: ${cost:,.2f} USD ({linked[0]['nombre_empresa']})")
                else:
                    cost = float(p_sel['precio_referencial'])
                    lbl_cost_info.configure(text=f"Costo de Referencia: ${cost:,.2f} USD (Sin proveedores enlazados)")
                
                try:
                    margin = float(e_margin.get())
                except ValueError:
                    margin = 30.0
                pv_sug = cost * (1 + margin / 100)
                e_pv.delete(0, 'end')
                e_pv.insert(0, f"{pv_sug:.2f}")

        p_menu = ctk.CTkOptionMenu(add_box, values=prod_names, width=220, command=update_cost_preview)
        p_menu.pack(side="left", padx=(0, 5))

        e_cant = ctk.CTkEntry(add_box, placeholder_text="Cant", width=55)
        e_cant.pack(side="left", padx=2)
        e_cant.insert(0, "1")

        e_margin = ctk.CTkEntry(add_box, placeholder_text="Margen %", width=70)
        e_margin.pack(side="left", padx=2)
        e_margin.insert(0, "30")
        e_margin.bind("<KeyRelease>", lambda event: update_cost_preview())

        e_pv = ctk.CTkEntry(add_box, placeholder_text="P. Venta", width=75)
        e_pv.pack(side="left", padx=2)
        e_pv.insert(0, "15.00")

        # Cargar primera visualización
        update_cost_preview()

        def add_item():
            p_sel = prod_map.get(p_menu.get())
            if p_sel:
                try:
                    cant = int(e_cant.get())
                    pv = float(e_pv.get())
                    
                    linked = SupplierModel.get_product_suppliers(p_sel['id'])
                    actual_cost = float(linked[0]['precio_cotizado']) if linked else float(p_sel['precio_referencial'])
                    chosen_prov_id = linked[0]['proveedor_id'] if linked else None
                    
                    selected_items.append({
                        "producto_id": p_sel['id'],
                        "nombre": p_sel['nombre'],
                        "cantidad": cant,
                        "precio_venta": pv,
                        "precio_costo": actual_cost,
                        "proveedor_id": chosen_prov_id
                    })
                    render_items()
                    update_tax_summary()
                except ValueError:
                    pass

        btn_add_it = AccentButton(add_box, "+ Item", command=add_item, width=80)
        btn_add_it.pack(side="left", padx=5)

        e_obs = ctk.CTkEntry(dialog, placeholder_text="Observaciones (ej. Contrato Gobierno N° 45 / Entregas en Guayaquil)", width=640)
        e_obs.pack(pady=10)

        def save_quote():
            c_sel = client_map.get(c_menu.get())
            if c_sel and selected_items:
                is_b2b = c_sel['tipo_cliente'] == 'B2B'
                QuoteModel.create_quote(c_sel['id'], is_b2b, selected_items, e_obs.get().strip())
                dialog.destroy()
                self.load_quotes()

        btn_save = PrimaryButton(dialog, "Generar Cotización Oficial", command=save_quote, width=640)
        btn_save.pack(pady=15)

    def open_logistics_dialog(self, quote):
        dialog = ctk.CTkToplevel(self)
        dialog.title(f"Gestión de Logística - Cot. {quote['numero_cotizacion']}")
        dialog.geometry("450x320")
        dialog.configure(fg_color=COLOR_BG_CARD)
        dialog.grab_set()

        ctk.CTkLabel(
            dialog, 
            text=f"LOGÍSTICA / ENTREGA DE PEDIDOS\nCotización N° {quote['numero_cotizacion']}", 
            font=ctk.CTkFont(size=13, weight="bold"), 
            text_color=COLOR_TEXT_PRIMARY
        ).pack(pady=15)

        ctk.CTkLabel(
            dialog, 
            text=f"Cliente: {quote['razon_social_nombre']}\nMonto: ${float(quote['total']):,.2f} USD\nEstado actual: {quote['estado']}", 
            font=ctk.CTkFont(size=12), 
            text_color=COLOR_TEXT_MUTED,
            justify="left"
        ).pack(pady=10)

        # Para los despachos, obtenemos los detalles de la cotización para restar stock de productos permanentes si corresponde
        def process_dispatch():
            if quote['estado'] in ['Facturada', 'Facturado']:
                from tkinter import messagebox
                messagebox.showwarning(
                    "Ya Despachado", 
                    "Esta cotización ya ha sido despachada y facturada anteriormente. No se puede volver a deducir el stock."
                )
                return
            # Obtener detalles de la cotización
            query_details = """
                SELECT d.*, p.nombre, p.tipo_stock, p.stock_actual
                FROM cotizacion_detalles d
                JOIN productos p ON d.producto_id = p.id
                WHERE d.cotizacion_id = %s
            """
            details = db.fetch_all(query_details, (quote['id'],))
            
            # Verificar stock de productos permanentes involucrados
            insufficient_stock = []
            for item in details:
                if item['tipo_stock'] == 'Permanente' and item['cantidad'] > item['stock_actual']:
                    insufficient_stock.append(f"{item['nombre']} (Requiere: {item['cantidad']}, Disponible: {item['stock_actual']})")
            
            if insufficient_stock:
                from tkinter import messagebox
                messagebox.showerror(
                    "Stock Insuficiente", 
                    "No se puede realizar el despacho completo. Productos con stock insuficiente:\n\n" + "\n".join(insufficient_stock)
                )
                return

            # Deducir el stock de productos permanentes
            for item in details:
                if item['tipo_stock'] == 'Permanente':
                    ProductModel.update_stock(item['producto_id'], -item['cantidad'])
            
            # Cambiar estado de la cotización a 'Facturada' (si no está ya en un estado final)
            if quote['estado'] not in ['Facturada', 'Facturado']:
                db.execute_query("UPDATE cotizaciones SET estado = 'Facturada' WHERE id = %s", (quote['id'],))

            # Obtener usuario actual
            root_win = self.winfo_toplevel()
            user_name = root_win.current_user.get('nombre_completo', 'Socio 2 - Compras y Mercadería') if hasattr(root_win, 'current_user') and root_win.current_user else 'Socio 2 - Compras y Mercadería'
            
            # Registrar auditoría de despacho
            AuditLogModel.log(
                user_name,
                "Despacho",
                f"Despacho de mercancía realizado para la Cotización N° {quote['numero_cotizacion']} de {quote['razon_social_nombre']}"
            )
            
            from tkinter import messagebox
            messagebox.showinfo("Logística", "¡Despacho de bodega realizado con éxito! Stock actualizado en inventario.")
            dialog.destroy()
            self.load_quotes()

        def process_delivery():
            # Obtener usuario actual
            root_win = self.winfo_toplevel()
            user_name = root_win.current_user.get('nombre_completo', 'Socio 2 - Compras y Mercadería') if hasattr(root_win, 'current_user') and root_win.current_user else 'Socio 2 - Compras y Mercadería'
            
            # Registrar auditoría de entrega física
            AuditLogModel.log(
                user_name,
                "Entrega física",
                f"Entrega física y recepción conforme del cliente registrada para la Cotización N° {quote['numero_cotizacion']} de {quote['razon_social_nombre']}"
            )
            
            from tkinter import messagebox
            messagebox.showinfo("Logística", "¡Recepción de entrega física registrada correctamente en la bitácora!")
            dialog.destroy()
            self.load_quotes()

        btn_box = ctk.CTkFrame(dialog, fg_color="transparent")
        btn_box.pack(fill="x", padx=20, pady=15)

        btn_dispatch = PrimaryButton(btn_box, "Despachar Bodega", command=process_dispatch, width=170)
        btn_dispatch.pack(side="left", padx=5, expand=True)

        btn_deliver = AccentButton(btn_box, "Registrar Entrega", command=process_delivery, width=170)
        btn_deliver.pack(side="right", padx=5, expand=True)

    def refresh_data(self):
        self.load_quotes()
