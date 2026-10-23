import {Routes,Route} from 'react-router-dom';
import Layout from '../components/layout/Layout.jsx';
import DashboardPage from '../pages/DashboardPage.jsx';
import InventarioPage from '../pages/InventarioPage.jsx';
import DeclaracionesPage from '../pages/DeclaracionesPage.jsx';
import DeclaracionDetallePage from '../pages/DeclaracionDetallePage.jsx';
import ContenedoresPage from '../pages/ContenedoresPage.jsx';
import BodegasPage from '../pages/BodegasPage.jsx';
import InspeccionesPage from '../pages/InspeccionesPage.jsx';
import MovimientosPage from '../pages/MovimientosPage.jsx';
import AsistentePage from '../pages/AsistentePage.jsx';
import NotFoundPage from '../pages/NotFoundPage.jsx';
export default function AppRoutes(){return <Routes><Route element={<Layout/>}><Route index element={<DashboardPage/>}/><Route path="inventario" element={<InventarioPage/>}/><Route path="declaraciones" element={<DeclaracionesPage/>}/><Route path="declaraciones/:id" element={<DeclaracionDetallePage/>}/><Route path="contenedores" element={<ContenedoresPage/>}/><Route path="bodegas" element={<BodegasPage/>}/><Route path="inspecciones" element={<InspeccionesPage/>}/><Route path="movimientos" element={<MovimientosPage/>}/><Route path="asistente" element={<AsistentePage/>}/><Route path="*" element={<NotFoundPage/>}/></Route></Routes>;}
