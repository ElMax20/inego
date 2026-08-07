import customtkinter as ctk
import os
from views.components import PrimaryButton, AccentButton
from config import COLOR_BG_MAIN, COLOR_BG_CARD, COLOR_TEXT_PRIMARY, COLOR_TEXT_MUTED, COLOR_ACCENT, COLOR_SUCCESS
from utils.excel_generator import export_sales_to_excel, export_gantt_chart_to_excel

class ReportsView(ctk.CTkFrame):
    def __init__(self, master, **kwargs):
        super().__init__(master, fg_color=COLOR_BG_MAIN, corner_radius=0, **kwargs)

        top_bar = ctk.CTkFrame(self, fg_color=COLOR_BG_CARD, height=60, corner_radius=0)
        top_bar.pack(fill="x", side="top")

        lbl_t = ctk.CTkLabel(
            top_bar, text="📊 Reportería Corporativa y Diagrama de Gantt en Excel",
            font=ctk.CTkFont(family="Segoe UI", size=16, weight="bold"),
            text_color=COLOR_TEXT_PRIMARY
        )
        lbl_t.pack(side="left", padx=20)

        self.scroll = ctk.CTkScrollableFrame(self, fg_color="transparent")
        self.scroll.pack(fill="both", expand=True, padx=20, pady=20)

        gantt_card = ctk.CTkFrame(self.scroll, fg_color=COLOR_BG_CARD, corner_radius=12)
        gantt_card.pack(fill="x", pady=(0, 20))

        g_title = ctk.CTkLabel(
            gantt_card, text="📅 Diagrama de Gantt en Excel (Contratos Gobierno y Logística)",
            font=ctk.CTkFont(family="Segoe UI", size=14, weight="bold"),
            text_color=COLOR_TEXT_PRIMARY
        )
        g_title.pack(anchor="w", padx=16, pady=(14, 6))

        g_desc = ctk.CTkLabel(
            gantt_card,
            text="Genera un archivo .xlsx estilizado con barras de avance cronológico, fases de compra, búsqueda de proveedores en Guayaquil e importaciones para los contratos ganados con el Gobierno.",
            font=ctk.CTkFont(size=11), text_color=COLOR_TEXT_MUTED, wraplength=700
        )
        g_desc.pack(anchor="w", padx=16, pady=(0, 12))

        btn_gantt = PrimaryButton(gantt_card, "Descargar e Abrir Diagrama de Gantt (.xlsx)", icon="📊", command=self.download_gantt, width=320)
        btn_gantt.pack(anchor="w", padx=16, pady=(0, 16))

        sales_card = ctk.CTkFrame(self.scroll, fg_color=COLOR_BG_CARD, corner_radius=12)
        sales_card.pack(fill="x")

        s_title = ctk.CTkLabel(
            sales_card, text="💵 Reportes de Ventas por Día, Mes y Rango de Fechas",
            font=ctk.CTkFont(family="Segoe UI", size=14, weight="bold"),
            text_color=COLOR_TEXT_PRIMARY
        )
        s_title.pack(anchor="w", padx=16, pady=(14, 6))

        filter_box = ctk.CTkFrame(sales_card, fg_color="transparent")
        filter_box.pack(fill="x", padx=16, pady=10)

        ctk.CTkLabel(filter_box, text="Fecha Inicio (YYYY-MM-DD):", text_color=COLOR_TEXT_MUTED).grid(row=0, column=0, padx=5, pady=5, sticky="w")
        self.e_from = ctk.CTkEntry(filter_box, placeholder_text="ej. 2026-08-01", width=160)
        self.e_from.grid(row=0, column=1, padx=5, pady=5)

        ctk.CTkLabel(filter_box, text="Fecha Fin (YYYY-MM-DD):", text_color=COLOR_TEXT_MUTED).grid(row=0, column=2, padx=5, pady=5, sticky="w")
        self.e_to = ctk.CTkEntry(filter_box, placeholder_text="ej. 2026-08-31", width=160)
        self.e_to.grid(row=0, column=3, padx=5, pady=5)

        btn_sales = AccentButton(sales_card, "Exportar Reporte de Ventas a Excel (.xlsx)", icon="📥", command=self.download_sales, width=320)
        btn_sales.pack(anchor="w", padx=16, pady=(10, 16))

        self.status_lbl = ctk.CTkLabel(self.scroll, text="", font=ctk.CTkFont(size=12, weight="bold"), text_color=COLOR_SUCCESS)
        self.status_lbl.pack(pady=10)

    def download_gantt(self):
        file_path = export_gantt_chart_to_excel()
        if os.path.exists(file_path):
            self.status_lbl.configure(text=f"✅ Diagrama de Gantt generado con éxito en: {os.path.basename(file_path)}")
            os.startfile(file_path)

    def download_sales(self):
        d_from = self.e_from.get().strip() or None
        d_to = self.e_to.get().strip() or None
        file_path = export_sales_to_excel(d_from, d_to)
        if os.path.exists(file_path):
            self.status_lbl.configure(text=f"✅ Reporte de ventas generado en: {os.path.basename(file_path)}")
            os.startfile(file_path)
