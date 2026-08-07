import customtkinter as ctk
from views.components import PrimaryButton, AccentButton
from config import COLOR_BG_MAIN, COLOR_BG_CARD, COLOR_TEXT_PRIMARY, COLOR_TEXT_MUTED, COLOR_ACCENT, COLOR_DANGER
from models.models import ExpenseModel
from database.connection import db

class ExpensesView(ctk.CTkFrame):
    def __init__(self, master, **kwargs):
        super().__init__(master, fg_color=COLOR_BG_MAIN, corner_radius=0, **kwargs)

        top_bar = ctk.CTkFrame(self, fg_color=COLOR_BG_CARD, height=60, corner_radius=0)
        top_bar.pack(fill="x", side="top")

        lbl_t = ctk.CTkLabel(
            top_bar, text="🧾 Control de Gastos, Agua, Servicios y Logística",
            font=ctk.CTkFont(family="Segoe UI", size=16, weight="bold"),
            text_color=COLOR_TEXT_PRIMARY
        )
        lbl_t.pack(side="left", padx=20)

        btn_new = PrimaryButton(top_bar, "Registrar Nuevo Gasto", icon="➕", command=self.open_new_expense_dialog)
        btn_new.pack(side="right", padx=20, pady=12)

        self.scroll = ctk.CTkScrollableFrame(self, fg_color="transparent")
        self.scroll.pack(fill="both", expand=True, padx=20, pady=20)

        self.load_expenses()

    def load_expenses(self):
        for w in self.scroll.winfo_children():
            w.destroy()

        expenses = ExpenseModel.get_all()

        if not expenses:
            ctk.CTkLabel(self.scroll, text="No hay gastos registrados en el sistema.", text_color=COLOR_TEXT_MUTED).pack(pady=30)
            return

        for g in expenses:
            card = ctk.CTkFrame(self.scroll, fg_color=COLOR_BG_CARD, corner_radius=10, border_width=1, border_color="#1E293B")
            card.pack(fill="x", pady=6)

            left_box = ctk.CTkFrame(card, fg_color="transparent")
            left_box.pack(side="left", padx=16, pady=12)

            con_lbl = ctk.CTkLabel(
                left_box, text=f"{g['concepto']} [{g['categoria']}]",
                font=ctk.CTkFont(family="Segoe UI", size=14, weight="bold"),
                text_color=COLOR_TEXT_PRIMARY
            )
            con_lbl.pack(anchor="w")

            info_lbl = ctk.CTkLabel(
                left_box,
                text=f"Fecha: {g['fecha']} | Método: {g['metodo_pago']} | Registrado Por: {g['registrado_por']} | N° Comp: {g['comprobante_nro'] or 'N/A'}",
                font=ctk.CTkFont(size=11), text_color=COLOR_TEXT_MUTED
            )
            info_lbl.pack(anchor="w", pady=(2, 0))

            right_box = ctk.CTkFrame(card, fg_color="transparent")
            right_box.pack(side="right", padx=16, pady=12)

            monto_lbl = ctk.CTkLabel(
                right_box, text=f"-${float(g['monto']):,.2f} USD",
                font=ctk.CTkFont(size=16, weight="bold"), text_color=COLOR_DANGER
            )
            monto_lbl.pack(padx=10)

    def open_new_expense_dialog(self):
        dialog = ctk.CTkToplevel(self)
        dialog.title("Registrar Gasto - Inego Industrias")
        dialog.geometry("450x520")
        dialog.configure(fg_color=COLOR_BG_CARD)
        dialog.grab_set()

        ctk.CTkLabel(dialog, text="REGISTRAR NUEVO GASTO / EGRESO", font=ctk.CTkFont(size=14, weight="bold"), text_color=COLOR_TEXT_PRIMARY).pack(pady=15)

        e_cat = ctk.CTkOptionMenu(dialog, values=["Agua y Servicios", "Logística y Envíos", "Gestión Operativa", "Compras Varias", "Mantenimiento", "Otros"], width=350)
        e_cat.pack(pady=6)

        e_con = ctk.CTkEntry(dialog, placeholder_text="Concepto (ej. Pago planilla de agua / Envío a obra)", width=350)
        e_con.pack(pady=6)

        e_mon = ctk.CTkEntry(dialog, placeholder_text="Monto USD ($)", width=350)
        e_mon.pack(pady=6)

        e_met = ctk.CTkOptionMenu(dialog, values=["Caja Chica", "Transferencia Banco", "Efectivo", "Tarjeta"], width=350)
        e_met.pack(pady=6)

        e_reg = ctk.CTkOptionMenu(dialog, values=["Socio 1 - Administrador", "Socio 2 - Compras", "Socio 3 - Contable"], width=350)
        e_reg.pack(pady=6)

        e_comp = ctk.CTkEntry(dialog, placeholder_text="Número de Comprobante / Factura (Opcional)", width=350)
        e_comp.pack(pady=6)

        def save():
            cat = e_cat.get()
            con = e_con.get().strip()
            try:
                mon = float(e_mon.get())
            except ValueError:
                return

            if con and mon > 0:
                ExpenseModel.create(cat, con, mon, e_met.get(), e_reg.get(), e_comp.get().strip())
                dialog.destroy()
                self.load_expenses()

        btn_save = PrimaryButton(dialog, "Guardar Gasto", command=save, width=350)
        btn_save.pack(pady=20)
