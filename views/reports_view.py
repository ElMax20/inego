import customtkinter as ctk
import os
from datetime import datetime
from views.components import PrimaryButton, AccentButton, CardFrame, StatusChip
from config import COLOR_BG_MAIN, COLOR_BG_CARD, COLOR_TEXT_PRIMARY, COLOR_TEXT_MUTED, COLOR_ACCENT, COLOR_SUCCESS, COLOR_PURPLE
from utils.excel_generator import export_sales_to_excel, export_gantt_chart_to_excel, export_expenses_to_excel

class ReportsView(ctk.CTkFrame):
    """ Vista de Reportería y Exportación a Excel / Gantt (Estilo SaaS UI) """
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
        self.scroll.pack(fill="both", expand=True, padx=22, pady=20)

        # 1. Card Diagrama de Gantt
        gantt_card = CardFrame(self.scroll)
        gantt_card.pack(fill="x", pady=(0, 20))

        g_head = ctk.CTkFrame(gantt_card, fg_color="transparent")
        g_head.pack(fill="x", padx=20, pady=(16, 6))

        g_title = ctk.CTkLabel(
            g_head, text="📅 Diagrama de Gantt en Excel (Contratos Gobierno y Logística)",
            font=ctk.CTkFont(family="Segoe UI", size=14, weight="bold"),
            text_color=COLOR_TEXT_PRIMARY
        )
        g_title.pack(side="left")

        chip_gantt = StatusChip(g_head, "FORMATO EXCEL .XLSX", "purple")
        chip_gantt.pack(side="right")

        g_desc = ctk.CTkLabel(
            gantt_card,
            text="Genera un archivo .xlsx estilizado con barras de avance cronológico, fases de compra, búsqueda de proveedores en Guayaquil e importaciones para los contratos ganados con el Gobierno.",
            font=ctk.CTkFont(size=11), text_color=COLOR_TEXT_MUTED, wraplength=720, justify="left"
        )
        g_desc.pack(anchor="w", padx=20, pady=(0, 14))

        btn_gantt = PrimaryButton(gantt_card, "Descargar y Abrir Diagrama de Gantt (.xlsx)", icon="📊", command=self.download_gantt, width=340)
        btn_gantt.pack(anchor="w", padx=20, pady=(0, 18))

        # 2. Card Reporte de Ventas
        sales_card = CardFrame(self.scroll)
        sales_card.pack(fill="x", pady=(0, 20))

        s_head = ctk.CTkFrame(sales_card, fg_color="transparent")
        s_head.pack(fill="x", padx=20, pady=(16, 6))

        s_title = ctk.CTkLabel(
            s_head, text="💵 Reportes de Ventas por Día, Mes y Rango de Fechas",
            font=ctk.CTkFont(family="Segoe UI", size=14, weight="bold"),
            text_color=COLOR_TEXT_PRIMARY
        )
        s_title.pack(side="left")

        chip_sales = StatusChip(s_head, "AUDITORÍA DE INGRESOS", "success")
        chip_sales.pack(side="right")

        # Accesos Rápidos
        quick_box = ctk.CTkFrame(sales_card, fg_color="transparent")
        quick_box.pack(fill="x", padx=20, pady=(6, 12))

        ctk.CTkLabel(quick_box, text="Accesos Rápidos de Ventas:", text_color=COLOR_TEXT_MUTED, font=ctk.CTkFont(weight="bold")).pack(side="left", padx=(0, 10))
        
        btn_today = PrimaryButton(quick_box, "📅 Ventas de Hoy", command=self.download_today_sales, width=180)
        btn_today.pack(side="left", padx=5)

        btn_month = PrimaryButton(quick_box, "🗓️ Ventas del Mes", command=self.download_month_sales, width=180)
        btn_month.pack(side="left", padx=5)

        # Filtro de rango personalizado
        filter_box = ctk.CTkFrame(sales_card, fg_color="transparent")
        filter_box.pack(fill="x", padx=20, pady=10)

        ctk.CTkLabel(filter_box, text="Fecha Inicio (YYYY-MM-DD):", text_color=COLOR_TEXT_MUTED).grid(row=0, column=0, padx=5, pady=5, sticky="w")
        self.e_from = ctk.CTkEntry(filter_box, placeholder_text="ej. 2026-08-01", width=150)
        self.e_from.grid(row=0, column=1, padx=5, pady=5)

        ctk.CTkLabel(filter_box, text="Fecha Fin (YYYY-MM-DD):", text_color=COLOR_TEXT_MUTED).grid(row=0, column=2, padx=5, pady=5, sticky="w")
        self.e_to = ctk.CTkEntry(filter_box, placeholder_text="ej. 2026-08-31", width=150)
        self.e_to.grid(row=0, column=3, padx=5, pady=5)

        btn_sales_range = AccentButton(sales_card, "Exportar Rango Personalizado a Excel (.xlsx)", icon="📥", command=self.download_sales, width=380)
        btn_sales_range.pack(anchor="w", padx=20, pady=(10, 18))

        # 3. Reporte de Caja Chica
        expenses_card = CardFrame(self.scroll)
        expenses_card.pack(fill="x", pady=(0, 20))

        ex_head = ctk.CTkFrame(expenses_card, fg_color="transparent")
        ex_head.pack(fill="x", padx=20, pady=(16, 6))

        ex_title = ctk.CTkLabel(
            ex_head, text="🧾 Reporte de Egresos y Caja Chica",
            font=ctk.CTkFont(family="Segoe UI", size=14, weight="bold"),
            text_color=COLOR_TEXT_PRIMARY
        )
        ex_title.pack(side="left")

        chip_exp = StatusChip(ex_head, "GASTOS OPERATIVOS", "warning")
        chip_exp.pack(side="right")

        ex_desc = ctk.CTkLabel(
            expenses_card,
            text="Genera un archivo Excel detallando todos los egresos y egresos manuales de caja chica clasificados por sus respectivos rubros (agua, transporte/logística, gestiones, compras varias) y con balance consolidado.",
            font=ctk.CTkFont(size=11), text_color=COLOR_TEXT_MUTED, wraplength=720, justify="left"
        )
        ex_desc.pack(anchor="w", padx=20, pady=(0, 12))

        btn_expenses = AccentButton(expenses_card, "Descargar Reporte de Gastos (.xlsx)", icon="📥", command=self.download_expenses, width=340)
        btn_expenses.pack(anchor="w", padx=20, pady=(0, 18))

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

    def download_today_sales(self):
        today = datetime.now().strftime("%Y-%m-%d")
        file_path = export_sales_to_excel(today, today)
        if os.path.exists(file_path):
            self.status_lbl.configure(text=f"✅ Reporte de ventas de HOY generado en: {os.path.basename(file_path)}")
            os.startfile(file_path)

    def download_month_sales(self):
        import calendar
        now = datetime.now()
        start_of_month = f"{now.year}-{now.month:02d}-01"
        last_day = calendar.monthrange(now.year, now.month)[1]
        end_of_month = f"{now.year}-{now.month:02d}-{last_day:02d}"
        
        file_path = export_sales_to_excel(start_of_month, end_of_month)
        if os.path.exists(file_path):
            self.status_lbl.configure(text=f"✅ Reporte de ventas del MES generado en: {os.path.basename(file_path)}")
            os.startfile(file_path)

    def download_expenses(self):
        file_path = export_expenses_to_excel()
        if os.path.exists(file_path):
            self.status_lbl.configure(text=f"✅ Reporte de gastos de caja chica generado en: {os.path.basename(file_path)}")
            os.startfile(file_path)
