import { Layout } from '@/components/Layout';
import { Card, CardBody } from '@/components/Card';

export default function SocietiesPage() {
  return (
    <Layout>
      <div className="space-y-6">
        <h1 className="text-3xl font-bold text-gray-900 dark:text-white">Societies</h1>
        <Card>
          <CardBody className="text-center py-12">
            <p className="text-xl font-semibold text-gray-900 dark:text-white mb-2">Coming Soon</p>
            <p className="text-gray-600 dark:text-gray-400">Society management features will be available in the next update.</p>
          </CardBody>
        </Card>
      </div>
    </Layout>
  );
}
