import customtkinter as ctk
import os
from views.components import PrimaryButton, AccentButton
from config import COLOR_BG_MAIN, COLOR_BG_CARD, COLOR_TEXT_PRIMARY, COLOR_TEXT_MUTED, COLOR_ACCENT, COLOR_SUCCESS, PARTNERS
from models.models import PayrollModel, AuditLogModel
from utils.pdf_generator import generate_payslip_pdf

class PayrollView(ctk.CTkFrame):
    def __init__(self, master, **kwargs):
        super().__init__(master, fg_color=COLOR_BG_MAIN, corner_radius=0, **kwargs)

        top_bar = ctk.CTkFrame(self, fg_color=COLOR_BG_CARD, height=60, corner_radius=0)
        top_bar.pack(fill="x", side="top")

        lbl_t = ctk.CTkLabel(
            top_bar, text="👔 Liquidación de Nómina de Socios ($50 Base + 5% Bono)",
            font=ctk.CTkFont(family="Segoe UI", size=16, weight="bold"),
            text_color=COLOR_TEXT_PRIMARY
        )
        lbl_t.pack(side="left", padx=20)

        btn_new = PrimaryButton(top_bar, "Generar Rol de Pago Socio", icon="➕", command=self.open_new_payroll_dialog)
        btn_new.pack(side="right", padx=20, pady=12)

        self.scroll = ctk.CTkScrollableFrame(self, fg_color="transparent")
        self.scroll.pack(fill="both", expand=True, padx=20, pady=20)

        self.load_payroll()

    def load_payroll(self):
        for w in self.scroll.winfo_children():
            w.destroy()

        records = PayrollModel.get_all()

        if not records:
            ctk.CTkLabel(self.scroll, text="No hay liquidaciones registradas.", text_color=COLOR_TEXT_MUTED).pack(pady=30)
            return

        for r in records:
            card = ctk.CTkFrame(self.scroll, fg_color=COLOR_BG_CARD, corner_radius=10, border_width=1, border_color="#1E293B")
            card.pack(fill="x", pady=6)

            left_box = ctk.CTkFrame(card, fg_color="transparent")
            left_box.pack(side="left", padx=16, pady=12)

            soc_lbl = ctk.CTkLabel(
                left_box, text=f"{r['socio_nombre']} | Período: {r['periodo_mes_anio']}",
                font=ctk.CTkFont(family="Segoe UI", size=14, weight="bold"),
                text_color=COLOR_TEXT_PRIMARY
            )
            soc_lbl.pack(anchor="w")

            info_lbl = ctk.CTkLabel(
                left_box,
                text=f"Base Fijo: $50.00 | Ventas Mes: ${float(r['total_ventas_mes']):,.2f} | Bono (5%): ${float(r['monto_bono_calculado']):,.2f} | Ajuste Contador: ${float(r['monto_bono_ajustado']):,.2f}",
                font=ctk.CTkFont(size=11), text_color=COLOR_TEXT_MUTED
            )
            info_lbl.pack(anchor="w", pady=(2, 0))

            right_box = ctk.CTkFrame(card, fg_color="transparent")
            right_box.pack(side="right", padx=16, pady=12)

            tot_lbl = ctk.CTkLabel(
                right_box, text=f"${float(r['total_pagar']):,.2f} USD",
                font=ctk.CTkFont(size=16, weight="bold"), text_color=COLOR_SUCCESS
            )
            tot_lbl.pack(side="left", padx=(0, 10))

            btn_pdf = AccentButton(right_box, "Imprimir Rol Físico", command=lambda rid=r['id']: self.print_payslip(rid), width=130)
            btn_pdf.pack(side="left")

    def print_payslip(self, payroll_id):
        pdf_path = generate_payslip_pdf(payroll_id)
        if pdf_path and os.path.exists(pdf_path):
            os.startfile(pdf_path)

    def open_new_payroll_dialog(self):
        dialog = ctk.CTkToplevel(self)
        dialog.title("Generar Rol de Pago Socio - Inego Industrias")
        dialog.geometry("450x450")
        dialog.configure(fg_color=COLOR_BG_CARD)
        dialog.grab_set()

        ctk.CTkLabel(dialog, text="LIQUIDACIÓN MENSUAL SOCIO", font=ctk.CTkFont(size=14, weight="bold"), text_color=COLOR_TEXT_PRIMARY).pack(pady=15)

        e_per = ctk.CTkEntry(dialog, placeholder_text="Período Mes/Año (ej. Agosto 2026)", width=350)
        e_per.pack(pady=6)

        e_soc = ctk.CTkOptionMenu(dialog, values=PARTNERS, width=350)
        e_soc.pack(pady=6)

        ctk.CTkLabel(dialog, text="Ajuste Manual del Bono por el Contador (USD):", text_color=COLOR_TEXT_MUTED).pack(anchor="w", padx=50, pady=(8, 0))
        e_bono = ctk.CTkEntry(dialog, placeholder_text="Valor Bono (Deja vacío para usar 5% automático)", width=350)
        e_bono.pack(pady=6)

        e_obs = ctk.CTkEntry(dialog, placeholder_text="Observaciones contables", width=350)
        e_obs.pack(pady=6)

        def save():
            per = e_per.get().strip()
            soc = e_soc.get()
            bono_val = None
            if e_bono.get().strip():
                try:
                    bono_val = float(e_bono.get().strip())
                except ValueError:
                    pass

            if per and soc:
                PayrollModel.calculate_and_save(per, soc, bono_val, e_obs.get().strip())
                
                root_win = self.winfo_toplevel()
                user_name = root_win.current_user.get('nombre_completo', 'Socio 3 - Proceso Contable') if hasattr(root_win, 'current_user') and root_win.current_user else 'Socio 3 - Proceso Contable'
                AuditLogModel.log(
                    user_name,
                    "Generación Rol",
                    f"Generado Rol de Pago de Socio para {soc} para el período {per}"
                )
                
                dialog.destroy()
                self.load_payroll()

        btn_save = PrimaryButton(dialog, "Calcular y Guardar Rol", command=save, width=350)
        btn_save.pack(pady=20)
