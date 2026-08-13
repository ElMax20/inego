import customtkinter as ctk
from views.components import PrimaryButton, AccentButton
from config import COLOR_BG_MAIN, COLOR_BG_CARD, COLOR_TEXT_PRIMARY, COLOR_TEXT_MUTED, COLOR_ACCENT, COLOR_SUCCESS, COLOR_WARNING, COLOR_DANGER
from models.models import ProductModel, AuditLogModel, SupplierModel
from database.connection import db

class InventoryView(ctk.CTkFrame):
    def __init__(self, master, **kwargs):
        super().__init__(master, fg_color=COLOR_BG_MAIN, corner_radius=0, **kwargs)

        top_bar = ctk.CTkFrame(self, fg_color=COLOR_BG_CARD, height=60, corner_radius=0)
        top_bar.pack(fill="x", side="top")

        lbl_t = ctk.CTkLabel(
            top_bar, text="📦 Catálogo de Productos y Control de Stock",
            font=ctk.CTkFont(family="Segoe UI", size=16, weight="bold"),
            text_color=COLOR_TEXT_PRIMARY
        )
        lbl_t.pack(side="left", padx=20)

        btn_new = PrimaryButton(top_bar, "Registrar Nuevo Producto", icon="➕", command=self.open_new_product_dialog)
        btn_new.pack(side="right", padx=20, pady=12)

        # Barra de búsqueda (RF2.7)
        search_frame = ctk.CTkFrame(self, fg_color="transparent")
        search_frame.pack(fill="x", padx=20, pady=(15, 0))

        self.search_entry = ctk.CTkEntry(
            search_frame, 
            placeholder_text="🔍 Buscar por código, nombre o categoría...", 
            width=400,
            height=32
        )
        self.search_entry.pack(side="left", padx=(0, 10))
        self.search_entry.bind("<KeyRelease>", lambda event: self.load_products())

        btn_clear = AccentButton(search_frame, "Limpiar", command=self.clear_search, width=80, height=32)
        btn_clear.pack(side="left")

        self.scroll = ctk.CTkScrollableFrame(self, fg_color="transparent")
        self.scroll.pack(fill="both", expand=True, padx=20, pady=15)

        self.load_products()

    def load_products(self):
        # Obtener filtro de búsqueda (RF2.7)
        search_query = self.search_entry.get().strip().lower() if hasattr(self, 'search_entry') else ""

        for w in self.scroll.winfo_children():
            w.destroy()

        products = ProductModel.get_all()

        if not products:
            lbl = ctk.CTkLabel(self.scroll, text="No hay productos registrados.", text_color=COLOR_TEXT_MUTED)
            lbl.pack(pady=30)
            return

        displayed_count = 0
        for p in products:
            # Filtrar por búsqueda (RF2.7)
            if search_query:
                match_cod = search_query in p['codigo'].lower()
                match_nom = search_query in p['nombre'].lower()
                match_cat = p['categoria'] and search_query in p['categoria'].lower()
                if not (match_cod or match_nom or match_cat):
                    continue

            displayed_count += 1
            card = ctk.CTkFrame(self.scroll, fg_color=COLOR_BG_CARD, corner_radius=10, border_width=1, border_color="#1E293B")
            card.pack(fill="x", pady=6)

            left_box = ctk.CTkFrame(card, fg_color="transparent")
            left_box.pack(side="left", padx=16, pady=12)

            name_lbl = ctk.CTkLabel(
                left_box, text=f"{p['nombre']} ({p['codigo']})",
                font=ctk.CTkFont(family="Segoe UI", size=14, weight="bold"),
                text_color=COLOR_TEXT_PRIMARY
            )
            name_lbl.pack(anchor="w")

            desc_lbl = ctk.CTkLabel(
                left_box, text=f"Categoría: {p['categoria']} | {p['descripcion'] or 'Sin descripción'}",
                font=ctk.CTkFont(size=11), text_color=COLOR_TEXT_MUTED
            )
            desc_lbl.pack(anchor="w", pady=(2, 0))

            # Obtener proveedores asociados (RF2.3)
            linked_sups = SupplierModel.get_product_suppliers(p['id'])
            if linked_sups:
                sups_text = "🔗 Proveedores: " + " | ".join([
                    f"{ls['nombre_empresa']} (${float(ls['precio_cotizado']):,.2f} - {ls['fecha_ultima_cotizacion']})"
                    for ls in linked_sups
                ])
            else:
                sups_text = "🔗 Sin proveedores asociados"
            
            sups_lbl = ctk.CTkLabel(
                left_box, text=sups_text,
                font=ctk.CTkFont(size=11, weight="bold"), text_color=COLOR_ACCENT,
                wraplength=600, justify="left"
            )
            sups_lbl.pack(anchor="w", pady=(4, 0))

            right_box = ctk.CTkFrame(card, fg_color="transparent")
            right_box.pack(side="right", padx=16, pady=12)

            is_perm = p['tipo_stock'] == 'Permanente'
            is_below_min = is_perm and p['stock_actual'] <= p['stock_minimo']
            
            if is_perm:
                if is_below_min:
                    badge_color = COLOR_DANGER
                    badge_txt = f"🚨 RE-STOCK REQUERIDO: {p['stock_actual']} unids (Mín: {p['stock_minimo']})"
                else:
                    badge_color = COLOR_SUCCESS
                    badge_txt = f"Stock Permanente: {p['stock_actual']} unids"
            else:
                badge_color = COLOR_WARNING
                badge_txt = "Bajo Pedido (Drop-shipping)"

            st_badge = ctk.CTkLabel(
                right_box, text=badge_txt,
                font=ctk.CTkFont(size=12, weight="bold"),
                text_color=badge_color, fg_color="#0F172A",
                corner_radius=6, padx=10, pady=4
            )
            st_badge.pack(side="left", padx=(0, 10))

            if is_perm:
                btn_add = AccentButton(right_box, "+ Stock", command=lambda pid=p['id']: self.add_stock_dialog(pid), width=80)
                btn_add.pack(side="left", padx=2)
                btn_dispatch = PrimaryButton(right_box, "🚚 Despacho", command=lambda pid=p['id']: self.dispatch_stock_dialog(pid), width=90)
                btn_dispatch.pack(side="left", padx=2)

            btn_link = AccentButton(right_box, "🔗 Enlazar", command=lambda pid=p['id']: self.open_link_supplier_dialog(pid), width=85)
            btn_link.pack(side="left", padx=2)

        if search_query and displayed_count == 0:
            lbl = ctk.CTkLabel(self.scroll, text="No se encontraron productos que coincidan con la búsqueda.", text_color=COLOR_TEXT_MUTED)
            lbl.pack(pady=30)

    def open_new_product_dialog(self):
        dialog = ctk.CTkToplevel(self)
        dialog.title("Nuevo Producto - Inego Industrias")
        dialog.geometry("450x520")
        dialog.configure(fg_color=COLOR_BG_CARD)
        dialog.grab_set()

        ctk.CTkLabel(dialog, text="REGISTRAR NUEVO PRODUCTO", font=ctk.CTkFont(size=14, weight="bold"), text_color=COLOR_TEXT_PRIMARY).pack(pady=15)

        e_cod = ctk.CTkEntry(dialog, placeholder_text="Código (ej. FER-005)", width=350)
        e_cod.pack(pady=6)

        e_nom = ctk.CTkEntry(dialog, placeholder_text="Nombre del Producto", width=350)
        e_nom.pack(pady=6)

        e_cat = ctk.CTkOptionMenu(dialog, values=["Ferretería General", "Tecnología y Software", "Suministros de Oficina"], width=350)
        e_cat.pack(pady=6)

        e_desc = ctk.CTkEntry(dialog, placeholder_text="Descripción corta", width=350)
        e_desc.pack(pady=6)

        ctk.CTkLabel(dialog, text="Tipo de Manejo de Stock:", text_color=COLOR_TEXT_MUTED).pack(anchor="w", padx=50, pady=(8, 0))
        e_tipo = ctk.CTkOptionMenu(dialog, values=["Bajo Pedido", "Permanente"], width=350)
        e_tipo.pack(pady=6)

        e_stock = ctk.CTkEntry(dialog, placeholder_text="Stock Inicial (Si es Permanente)", width=350)
        e_stock.pack(pady=6)
        e_stock.insert(0, "0")

        e_precio = ctk.CTkEntry(dialog, placeholder_text="Precio Referencial ($ USD)", width=350)
        e_precio.pack(pady=6)
        e_precio.insert(0, "0.00")

        def save():
            cod = e_cod.get().strip()
            nom = e_nom.get().strip()
            cat = e_cat.get()
            desc = e_desc.get().strip()
            tipo = e_tipo.get()
            try:
                st = int(e_stock.get() or 0)
                pr = float(e_precio.get() or 0.0)
            except ValueError:
                return

            if cod and nom:
                ProductModel.create(cod, nom, cat, desc, tipo, st, pr)
                dialog.destroy()
                self.load_products()

        btn_save = PrimaryButton(dialog, "Guardar Producto", command=save, width=350)
        btn_save.pack(pady=20)

    def add_stock_dialog(self, product_id):
        dialog = ctk.CTkInputDialog(text="Ingrese la cantidad de stock a ingresar:", title="Agregar Stock")
        val = dialog.get_input()
        if val and val.isdigit():
            qty = int(val)
            ProductModel.update_stock(product_id, qty)
            
            # Auditoría automática (RF1.3)
            prod = ProductModel.get_by_id(product_id)
            root_win = self.winfo_toplevel()
            user_name = root_win.current_user.get('nombre_completo', 'Socio 2 - Compras y Mercadería') if hasattr(root_win, 'current_user') and root_win.current_user else 'Socio 2 - Compras y Mercadería'
            AuditLogModel.log(
                user_name,
                "Compra",
                f"Ingreso de stock (Compra) de {qty} unidades para el producto '{prod['nombre']}'"
            )
            
            self.load_products()

    def dispatch_stock_dialog(self, product_id):
        prod = ProductModel.get_by_id(product_id)
        if not prod:
            return
            
        dialog = ctk.CTkInputDialog(text=f"Stock disponible: {prod['stock_actual']} unids.\nIngrese la cantidad a despachar/entregar:", title="Despachar Stock")
        val = dialog.get_input()
        if val and val.isdigit():
            qty = int(val)
            if qty > prod['stock_actual']:
                from tkinter import messagebox
                messagebox.showerror("Error de Stock", f"No hay suficiente stock. Stock disponible: {prod['stock_actual']} unidades.")
                return
                
            ProductModel.update_stock(product_id, -qty)
            
            # Auditoría automática (RF1.3)
            root_win = self.winfo_toplevel()
            user_name = root_win.current_user.get('nombre_completo', 'Socio 2 - Compras y Mercadería') if hasattr(root_win, 'current_user') and root_win.current_user else 'Socio 2 - Compras y Mercadería'
            
            # Registrar despacho en la bitácora
            AuditLogModel.log(
                user_name,
                "Despacho",
                f"Despacho manual de {qty} unidades del producto '{prod['nombre']}'"
            )
            # Registrar entrega física en la bitácora
            AuditLogModel.log(
                user_name,
                "Entrega física",
                f"Entrega física manual de {qty} unidades del producto '{prod['nombre']}'"
            )
            
            self.load_products()

    def refresh_data(self):
        self.load_products()

    def clear_search(self):
        self.search_entry.delete(0, 'end')
        self.load_products()

    def open_link_supplier_dialog(self, product_id):
        prod = ProductModel.get_by_id(product_id)
        if not prod:
            return
            
        dialog = ctk.CTkToplevel(self)
        dialog.title(f"Enlazar Proveedor - {prod['nombre']}")
        dialog.geometry("450x420")
        dialog.configure(fg_color=COLOR_BG_CARD)
        dialog.grab_set()

        ctk.CTkLabel(
            dialog, 
            text=f"ENLAZAR PROVEEDOR A PRODUCTO\n{prod['nombre']} ({prod['codigo']})", 
            font=ctk.CTkFont(size=13, weight="bold"), 
            text_color=COLOR_TEXT_PRIMARY
        ).pack(pady=15)

        suppliers = SupplierModel.get_all()
        sup_map = {s['nombre_empresa']: s for s in suppliers}
        sup_names = list(sup_map.keys())
        
        if not sup_names:
            ctk.CTkLabel(dialog, text="⚠️ Registre proveedores primero en el sistema.", text_color=COLOR_WARNING).pack(pady=20)
            return

        ctk.CTkLabel(dialog, text="Seleccione Proveedor:", text_color=COLOR_TEXT_MUTED).pack(anchor="w", padx=50, pady=(10, 0))
        e_sup = ctk.CTkOptionMenu(dialog, values=sup_names, width=350)
        e_sup.pack(pady=6)

        e_cost = ctk.CTkEntry(dialog, placeholder_text="Costo Última Cotización ($ USD)", width=350)
        e_cost.pack(pady=6)
        e_cost.insert(0, f"{float(prod['precio_referencial']):.2f}")

        e_days = ctk.CTkEntry(dialog, placeholder_text="Tiempo de Entrega (Días)", width=350)
        e_days.pack(pady=6)
        e_days.insert(0, "1")

        ctk.CTkLabel(dialog, text="Disponibilidad del Proveedor:", text_color=COLOR_TEXT_MUTED).pack(anchor="w", padx=50, pady=(6, 0))
        e_disp = ctk.CTkOptionMenu(
            dialog, 
            values=["En Stock Proveedor", "Bajo Pedido 24-48h", "Agotado"],
            width=350
        )
        e_disp.pack(pady=6)

        def save():
            sup_sel = sup_map.get(e_sup.get())
            if not sup_sel:
                return
            try:
                cost = float(e_cost.get())
                days = int(e_days.get())
            except ValueError:
                from tkinter import messagebox
                messagebox.showerror("Error de Formato", "El costo y los días de entrega deben ser valores numéricos válidos.")
                return
                
            SupplierModel.link_product(
                producto_id=prod['id'],
                proveedor_id=sup_sel['id'],
                precio_cotizado=cost,
                tiempo_entrega_dias=days,
                disponibilidad=e_disp.get()
            )
            
            # Auditoría automática (RF1.3)
            root_win = self.winfo_toplevel()
            user_name = root_win.current_user.get('nombre_completo', 'Socio 2 - Compras y Mercadería') if hasattr(root_win, 'current_user') and root_win.current_user else 'Socio 2 - Compras y Mercadería'
            AuditLogModel.log(
                user_name,
                "Enlace Proveedor",
                f"Enlazado proveedor '{sup_sel['nombre_empresa']}' a producto '{prod['nombre']}' con costo ${cost:,.2f} USD"
            )
            
            dialog.destroy()
            self.load_products()

        btn_save = PrimaryButton(dialog, "Guardar Enlace", command=save, width=350)
        btn_save.pack(pady=20)
