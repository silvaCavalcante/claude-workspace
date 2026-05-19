# Playwright Spec Template

Use este template ao gerar arquivos `.spec.ts` após uma execução bem-sucedida.

---

## Template base

```typescript
import { test, expect } from '@playwright/test';

// Gerado automaticamente por Claude Playwright Agent
// Data: [timestamp]
// Fluxo: [nome do fluxo testado]

test.describe('[Nome do módulo]', () => {
  
  // Configuração compartilhada (se necessário)
  test.beforeEach(async ({ page }) => {
    await page.goto('[URL_BASE]');
  });

  test('[descrição do teste em linguagem natural]', async ({ page }) => {
    
    // --- Arrange ---
    // Preparação de dados ou estado inicial
    
    // --- Act ---
    // Ações executadas
    await page.getByLabel('[label do campo]').fill('[valor]');
    await page.getByRole('button', { name: '[texto do botão]' }).click();
    
    // --- Assert ---
    // Verificações
    await expect(page).toHaveURL('/[rota-esperada]');
    await expect(page.getByText('[texto esperado]')).toBeVisible();
  });

  test('deve exibir erro para credenciais inválidas', async ({ page }) => {
    await page.getByLabel('Email').fill('invalido@teste.com');
    await page.getByLabel('Senha').fill('senhaerrada');
    await page.getByRole('button', { name: 'Entrar' }).click();
    
    await expect(page.getByText('[mensagem de erro]')).toBeVisible();
  });

});
```

---

## Regras para geração do spec

1. **Use locators semânticos** na seguinte ordem de preferência:
   - `getByRole` — melhor opção (acessível e resiliente)
   - `getByLabel` — para inputs com label
   - `getByText` — para elementos com texto visível
   - `getByTestId` — se o app usa `data-testid`
   - `locator('css')` — último recurso, documente o motivo

2. **Nunca use** seletores frágeis como:
   - IDs gerados dinamicamente (`#btn-a1b2c3`)
   - Seletores por posição (`.container > div:nth-child(2)`)
   - XPath complexo

3. **Organize em Arrange/Act/Assert** para legibilidade

4. **Agrupe testes relacionados** em `test.describe`

5. **Use variáveis para dados de teste**:
```typescript
const TEST_USER = {
  email: 'user@teste.com',
  password: '123456',
  name: 'João Silva'
};
```

6. **Adicione comentário de origem** no topo do arquivo indicando que foi gerado pelo agente

---

## Exemplo completo — Fluxo de Login

```typescript
import { test, expect } from '@playwright/test';

// Gerado por Claude Playwright Agent
// Fluxo: Login com credenciais válidas e inválidas

const TEST_USER = {
  email: 'user@teste.com',
  password: '123456',
  name: 'João Silva'
};

test.describe('Autenticação', () => {

  test.beforeEach(async ({ page }) => {
    await page.goto('/login');
  });

  test('login com credenciais válidas redireciona para dashboard', async ({ page }) => {
    await page.getByLabel('Email').fill(TEST_USER.email);
    await page.getByLabel('Senha').fill(TEST_USER.password);
    await page.getByRole('button', { name: 'Entrar' }).click();

    await expect(page).toHaveURL('/dashboard');
    await expect(page.getByText(`Bem-vindo, ${TEST_USER.name}`)).toBeVisible();
  });

  test('login com credenciais inválidas exibe mensagem de erro', async ({ page }) => {
    await page.getByLabel('Email').fill('wrong@email.com');
    await page.getByLabel('Senha').fill('senhaerrada');
    await page.getByRole('button', { name: 'Entrar' }).click();

    await expect(page.getByText('Email ou senha incorretos')).toBeVisible();
    await expect(page).toHaveURL('/login');
  });

  test('campos obrigatórios exibem validação quando vazios', async ({ page }) => {
    await page.getByRole('button', { name: 'Entrar' }).click();

    await expect(page.getByText('Email é obrigatório')).toBeVisible();
    await expect(page.getByText('Senha é obrigatória')).toBeVisible();
  });

});
```
