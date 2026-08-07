import customtkinter as ctk
from views.components import PrimaryButton, AccentButton
from config import COLOR_BG_MAIN, COLOR_BG_CARD, COLOR_TEXT_PRIMARY, COLOR_TEXT_MUTED, COLOR_ACCENT, COLOR_SUCCESS, COLOR_WARNING
from models.models import ProductModel
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

        self.scroll = ctk.CTkScrollableFrame(self, fg_color="transparent")
        self.scroll.pack(fill="both", expand=True, padx=20, pady=20)

        self.load_products()

    def load_products(self):
        for w in self.scroll.winfo_children():
            w.destroy()

        products = ProductModel.get_all()

        if not products:
            lbl = ctk.CTkLabel(self.scroll, text="No hay productos registrados.", text_color=COLOR_TEXT_MUTED)
            lbl.pack(pady=30)
            return

        for p in products:
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

            right_box = ctk.CTkFrame(card, fg_color="transparent")
            right_box.pack(side="right", padx=16, pady=12)

            is_perm = p['tipo_stock'] == 'Permanente'
            badge_color = COLOR_SUCCESS if is_perm else COLOR_WARNING
            badge_txt = f"Stock Permanente: {p['stock_actual']} unids" if is_perm else "Bajo Pedido (Drop-shipping)"

            st_badge = ctk.CTkLabel(
                right_box, text=badge_txt,
                font=ctk.CTkFont(size=12, weight="bold"),
                text_color=badge_color, fg_color="#0F172A",
                corner_radius=6, padx=10, pady=4
            )
            st_badge.pack(side="left", padx=(0, 10))

            if is_perm:
                btn_add = AccentButton(right_box, "+ Stock", command=lambda pid=p['id']: self.add_stock_dialog(pid), width=80)
                btn_add.pack(side="left")

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
            ProductModel.update_stock(product_id, int(val))
            self.load_products()
