import customtkinter as ctk
from views.components import PrimaryButton, AccentButton
from config import COLOR_BG_MAIN, COLOR_BG_CARD, COLOR_TEXT_PRIMARY, COLOR_TEXT_MUTED, COLOR_ACCENT, COLOR_SUCCESS
from models.models import SupplierModel

class SuppliersView(ctk.CTkFrame):
    def __init__(self, master, **kwargs):
        super().__init__(master, fg_color=COLOR_BG_MAIN, corner_radius=0, **kwargs)

        top_bar = ctk.CTkFrame(self, fg_color=COLOR_BG_CARD, height=60, corner_radius=0)
        top_bar.pack(fill="x", side="top")

        lbl_t = ctk.CTkLabel(
            top_bar, text="🏭 Gestión de Proveedores por Categoría y Ubicación",
            font=ctk.CTkFont(family="Segoe UI", size=16, weight="bold"),
            text_color=COLOR_TEXT_PRIMARY
        )
        lbl_t.pack(side="left", padx=20)

        btn_new = PrimaryButton(top_bar, "Registrar Nuevo Proveedor", icon="➕", command=self.open_new_supplier_dialog)
        btn_new.pack(side="right", padx=20, pady=12)

        self.tabview = ctk.CTkTabview(self, fg_color=COLOR_BG_MAIN, segmented_button_fg_color=COLOR_BG_CARD, segmented_button_selected_color=COLOR_ACCENT)
        self.tabview.pack(fill="both", expand=True, padx=20, pady=10)

        self.tab_gye = self.tabview.add("Guayaquil (90%)")
        self.tab_prov = self.tabview.add("Otras Provincias")
        self.tab_imp = self.tabview.add("Importados (Amazon / Tiendamia)")

        self.load_suppliers()

    def load_suppliers(self):
        for tab in [self.tab_gye, self.tab_prov, self.tab_imp]:
            for w in tab.winfo_children():
                w.destroy()

        suppliers = SupplierModel.get_all()

        scroll_gye = ctk.CTkScrollableFrame(self.tab_gye, fg_color="transparent")
        scroll_gye.pack(fill="both", expand=True)

        scroll_prov = ctk.CTkScrollableFrame(self.tab_prov, fg_color="transparent")
        scroll_prov.pack(fill="both", expand=True)

        scroll_imp = ctk.CTkScrollableFrame(self.tab_imp, fg_color="transparent")
        scroll_imp.pack(fill="both", expand=True)

        for s in suppliers:
            tipo = s['tipo_proveedor']
            target_scroll = scroll_gye
            if tipo == 'Otras Provincias':
                target_scroll = scroll_prov
            elif tipo in ['Amazon', 'Tiendamia']:
                target_scroll = scroll_imp

            card = ctk.CTkFrame(target_scroll, fg_color=COLOR_BG_CARD, corner_radius=10, border_width=1, border_color="#1E293B")
            card.pack(fill="x", pady=6)

            left_box = ctk.CTkFrame(card, fg_color="transparent")
            left_box.pack(side="left", padx=16, pady=12)

            comp_lbl = ctk.CTkLabel(
                left_box, text=s['nombre_empresa'],
                font=ctk.CTkFont(family="Segoe UI", size=14, weight="bold"),
                text_color=COLOR_TEXT_PRIMARY
            )
            comp_lbl.pack(anchor="w")

            info_lbl = ctk.CTkLabel(
                left_box,
                text=f"RUC: {s['ruc_cedula'] or 'N/A'} | Contacto: {s['contacto_nombre']} | Tel: {s['telefono']} | Email: {s['email']}",
                font=ctk.CTkFont(size=11), text_color=COLOR_TEXT_MUTED
            )
            info_lbl.pack(anchor="w", pady=(2, 0))

            cat_lbl = ctk.CTkLabel(
                left_box,
                text=f"Categoría: {s['categoria_nombre'] or 'General'} | Ubicación: {s['ubicacion']}",
                font=ctk.CTkFont(size=11, weight="bold"), text_color=COLOR_ACCENT
            )
            cat_lbl.pack(anchor="w", pady=(2, 0))

    def open_new_supplier_dialog(self):
        dialog = ctk.CTkToplevel(self)
        dialog.title("Nuevo Proveedor - Inego Industrias")
        dialog.geometry("450x520")
        dialog.configure(fg_color=COLOR_BG_CARD)
        dialog.grab_set()

        ctk.CTkLabel(dialog, text="REGISTRAR NUEVO PROVEEDOR", font=ctk.CTkFont(size=14, weight="bold"), text_color=COLOR_TEXT_PRIMARY).pack(pady=15)

        e_emp = ctk.CTkEntry(dialog, placeholder_text="Nombre Empresa / Razón Social", width=350)
        e_emp.pack(pady=6)

        e_ruc = ctk.CTkEntry(dialog, placeholder_text="RUC / Cédula", width=350)
        e_ruc.pack(pady=6)

        e_cont = ctk.CTkEntry(dialog, placeholder_text="Nombre de Contacto", width=350)
        e_cont.pack(pady=6)

        e_tel = ctk.CTkEntry(dialog, placeholder_text="Teléfono", width=350)
        e_tel.pack(pady=6)

        e_email = ctk.CTkEntry(dialog, placeholder_text="Correo Electrónico", width=350)
        e_email.pack(pady=6)

        e_tipo = ctk.CTkOptionMenu(dialog, values=["Guayaquil (90%)", "Otras Provincias", "Amazon", "Tiendamia"], width=350)
        e_tipo.pack(pady=6)

        cats = SupplierModel.get_categories()
        cat_names = [c['nombre'] for c in cats] or ["Ferretería General", "Tecnología y Software", "Suministros de Oficina"]
        e_cat = ctk.CTkOptionMenu(dialog, values=cat_names, width=350)
        e_cat.pack(pady=6)

        def save():
            emp = e_emp.get().strip()
            if emp:
                c_id = 1
                for c in cats:
                    if c['nombre'] == e_cat.get():
                        c_id = c['id']
                        break
                
                SupplierModel.create(emp, e_ruc.get().strip(), e_cont.get().strip(), e_tel.get().strip(), e_email.get().strip(), "Guayaquil" if e_tipo.get() == "Guayaquil (90%)" else "Exterior", c_id, e_tipo.get())
                dialog.destroy()
                self.load_suppliers()

        btn_save = PrimaryButton(dialog, "Guardar Proveedor", command=save, width=350)
        btn_save.pack(pady=20)
