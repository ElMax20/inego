import customtkinter as ctk
from views.components import MetricCard, PrimaryButton, AccentButton, StatusChip, CardFrame
from config import COLOR_BG_MAIN, COLOR_BG_CARD, COLOR_TEXT_PRIMARY, COLOR_TEXT_MUTED, COLOR_ACCENT, COLOR_WARNING, COLOR_SUCCESS, COLOR_DANGER, COLOR_PURPLE
from database.connection import db

class DashboardView(ctk.CTkFrame):
    """ Panel Principal y Dashboard de Métricas Corporativas (Rediseño SaaS UI) """
    def __init__(self, master, navigate_callback=None, **kwargs):
        super().__init__(master, fg_color=COLOR_BG_MAIN, corner_radius=0, **kwargs)
        self.navigate_callback = navigate_callback

        self.scroll = ctk.CTkScrollableFrame(self, fg_color="transparent")
        self.scroll.pack(fill="both", expand=True, padx=22, pady=20)

        # 1. Cuadrícula de Métricas KPI SaaS
        self.kpi_frame = ctk.CTkFrame(self.scroll, fg_color="transparent")
        self.kpi_frame.pack(fill="x", pady=(0, 22))

        self.kpi_ventas = MetricCard(self.kpi_frame, "Ventas Totales Mes", "$0.00", "💵", "Acumulado Facturado", "▲ +15.4%", COLOR_SUCCESS)
        self.kpi_ventas.pack(side="left", fill="x", expand=True, padx=(0, 8))

        self.kpi_gastos = MetricCard(self.kpi_frame, "Gastos y Operativa", "$0.00", "🧾", "Agua, Logística y Gestión", "▼ -3.2%", COLOR_ACCENT)
        self.kpi_gastos.pack(side="left", fill="x", expand=True, padx=4)

        self.kpi_credito = MetricCard(self.kpi_frame, "Créditos B2B Vivos", "$0.00", "⏳", "Por Cobrar Gobierno 72d", "⚡ En Monitoreo", COLOR_WARNING)
        self.kpi_credito.pack(side="left", fill="x", expand=True, padx=4)

        self.kpi_cotiz = MetricCard(self.kpi_frame, "Cotizaciones Activas", "0", "📋", "Historial de Clientes", "▲ +8.0%", COLOR_PURPLE)
        self.kpi_cotiz.pack(side="left", fill="x", expand=True, padx=(8, 0))

        # 2. Fila Media: Monitoreo de Stock Fijo y Accesos Rápidos
        middle_frame = ctk.CTkFrame(self.scroll, fg_color="transparent")
        middle_frame.pack(fill="x", pady=(0, 22))

        stock_card = CardFrame(middle_frame)
        stock_card.pack(side="left", fill="both", expand=True, padx=(0, 10))

        st_header = ctk.CTkFrame(stock_card, fg_color="transparent")
        st_header.pack(fill="x", padx=18, pady=(16, 6))

        st_title = ctk.CTkLabel(
            st_header, text="📦 Control de Stock Permanente (Items Fijos)",
            font=ctk.CTkFont(family="Segoe UI", size=14, weight="bold"),
            text_color=COLOR_TEXT_PRIMARY
        )
        st_title.pack(side="left")

        chip_mon = StatusChip(st_header, "MONITOREO EN VIVO", "accent")
        chip_mon.pack(side="right")

        st_desc = ctk.CTkLabel(
            stock_card, text="Monitoreo de productos de rotación continua (Cuchillas de doble filo, Licencias Office):",
            font=ctk.CTkFont(family="Segoe UI", size=11), text_color=COLOR_TEXT_MUTED
        )
        st_desc.pack(anchor="w", padx=18, pady=(0, 12))

        self.stock_list_frame = ctk.CTkFrame(stock_card, fg_color="transparent")
        self.stock_list_frame.pack(fill="both", expand=True, padx=18, pady=(0, 16))

        # Tarjeta de Accesos Rápidos
        actions_card = CardFrame(middle_frame)
        actions_card.pack(side="right", fill="both", expand=True, padx=(10, 0))

        ac_title = ctk.CTkLabel(
            actions_card, text="⚡ Accesos Rápidos y Logística",
            font=ctk.CTkFont(family="Segoe UI", size=14, weight="bold"),
            text_color=COLOR_TEXT_PRIMARY
        )
        ac_title.pack(anchor="w", padx=18, pady=(16, 12))

        btn1 = PrimaryButton(actions_card, "Nueva Cotización / Comparar", icon="📋", command=lambda: self._nav("quotes"))
        btn1.pack(fill="x", padx=18, pady=5)

        btn2 = AccentButton(actions_card, "Registrar Gasto u Operativa", icon="💸", command=lambda: self._nav("expenses"))
        btn2.pack(fill="x", padx=18, pady=5)

        btn3 = PrimaryButton(actions_card, "Descargar Diagrama de Gantt Excel", icon="📊", command=lambda: self._nav("reports"))
        btn3.pack(fill="x", padx=18, pady=5)

        btn4 = AccentButton(actions_card, "Calcular Nómina de 3 Socios ($50 + 5%)", icon="👔", command=lambda: self._nav("payroll"))
        btn4.pack(fill="x", padx=18, pady=(5, 16))

        self.refresh_data()

    def _nav(self, route):
        if self.navigate_callback:
            self.navigate_callback(route)

    def refresh_data(self):
        r_ventas = db.fetch_one("SELECT SUM(total) as total FROM cotizaciones WHERE estado IN ('Facturada', 'Aprobada')")
        tot_ventas = float(r_ventas['total'] or 0.0) if r_ventas else 0.0
        self.kpi_ventas.set_value(f"${tot_ventas:,.2f}")

        r_gastos = db.fetch_one("SELECT SUM(monto) as total FROM gastos")
        tot_gastos = float(r_gastos['total'] or 0.0) if r_gastos else 0.0
        self.kpi_gastos.set_value(f"${tot_gastos:,.2f}")

        r_cred = db.fetch_one("SELECT SUM(total) as total FROM cotizaciones WHERE es_credito_72dias = 1 AND estado = 'Facturada'")
        tot_cred = float(r_cred['total'] or 0.0) if r_cred else 0.0
        self.kpi_credito.set_value(f"${tot_cred:,.2f}")

        r_cot = db.fetch_one("SELECT COUNT(*) as cnt FROM cotizaciones")
        cnt_cot = r_cot['cnt'] if r_cot else 0
        self.kpi_cotiz.set_value(str(cnt_cot))

        for widget in self.stock_list_frame.winfo_children():
            widget.destroy()

        perm_prods = db.fetch_all("SELECT * FROM productos WHERE tipo_stock = 'Permanente'")
        for p in perm_prods:
            is_alert = p['stock_actual'] <= p['stock_minimo']
            row_color = ("#FEE2E2", "#381414") if is_alert else ("#F5F8FA", "#2B3342")
            text_color = COLOR_DANGER if is_alert else COLOR_TEXT_PRIMARY

            row = ctk.CTkFrame(self.stock_list_frame, fg_color=row_color, corner_radius=8, border_width=1, border_color=("#D5DEE5", "#3F4A5C"))
            row.pack(fill="x", pady=4)

            lbl_text = f"🚨 {p['nombre']} [{p['codigo']}]" if is_alert else f"• {p['nombre']} [{p['codigo']}]"
            lbl = ctk.CTkLabel(row, text=lbl_text, font=ctk.CTkFont(size=12, weight="bold"), text_color=text_color)
            lbl.pack(side="left", padx=12, pady=8)

            if is_alert:
                chip_alert = StatusChip(row, f"RE-STOCK REQUERIDO: {p['stock_actual']} unids", "danger")
                chip_alert.pack(side="right", padx=10)
            else:
                chip_ok = StatusChip(row, f"Stock: {p['stock_actual']} unids", "success")
                chip_ok.pack(side="right", padx=10)
