-- ============================================================================
-- BarberApp - Migración 0007: Pagos y Comprobantes QR
-- ============================================================================

-- RPC: subir_comprobante_pago
-- El cliente sube la captura de su transferencia QR bancaria.
create or replace function subir_comprobante_pago(
  p_cita_id uuid,
  p_monto numeric,
  p_url_comprobante text
)
returns uuid as $$
declare
  v_barberia_id uuid;
  v_pago_id uuid;
begin
  select barberia_id into v_barberia_id from citas where id = p_cita_id;
  if v_barberia_id is null then
    raise exception 'Cita no encontrada';
  end if;

  insert into pagos (
    cita_id,
    barberia_id,
    monto,
    metodo,
    estado,
    url_comprobante,
    creado_en
  ) values (
    p_cita_id,
    v_barberia_id,
    p_monto,
    'qr_manual',
    'por_verificar',
    p_url_comprobante,
    now()
  )
  returning id into v_pago_id;

  return v_pago_id;
end;
$$ language plpgsql security definer;

-- RPC: confirmar_pago
-- El admin confirma la llegada del dinero a su cuenta bancaria.
create or replace function confirmar_pago(
  p_pago_id uuid
)
returns void as $$
begin
  update pagos
  set estado = 'confirmado',
      verificado_por = auth.uid(),
      actualizado_en = now()
  where id = p_pago_id;

  update citas
  set estado = 'confirmada',
      actualizado_en = now()
  where id = (select cita_id from pagos where id = p_pago_id);
end;
$$ language plpgsql security definer;

-- RPC: rechazar_pago
-- El admin rechaza el comprobante (inválido/trucado).
create or replace function rechazar_pago(
  p_pago_id uuid
)
returns void as $$
begin
  update pagos
  set estado = 'rechazado',
      verificado_por = auth.uid(),
      actualizado_en = now()
  where id = p_pago_id;
end;
$$ language plpgsql security definer;
